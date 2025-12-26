from datetime import timedelta

from django.db.models import F, Sum, Count, Max, FloatField
from django.db.models.functions import Coalesce
from django.utils import timezone
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.models import User
from games.models import Game, GamePlayer, GameStatistics
from training.models import TrainingSession
from .models import UserStatistics, PersonalBest, AppUsageEvent
from .serializers import UserStatisticsSerializer, PersonalBestSerializer, AppUsageEventSerializer


class IsAuthenticatedOrReadOnly(permissions.BasePermission):
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return request.user and request.user.is_authenticated


class AppUsageEventView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = AppUsageEventSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        event = serializer.save()
        return Response({"id": event.id}, status=status.HTTP_201_CREATED)


class StatsSummaryView(APIView):
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get(self, request):
        user = request.user

        # Base queryset of player appearances
        player_qs = GamePlayer.objects.filter(user=user)
        total_games = player_qs.count()
        wins = Game.objects.filter(winner=user).count()
        losses = max(total_games - wins, 0)
        win_pct = round((wins / total_games) * 100, 2) if total_games else 0

        stats_qs = GameStatistics.objects.filter(game_player__in=player_qs)

        totals = stats_qs.aggregate(
            darts=Coalesce(Sum("total_throws"), 0, output_field=FloatField()),
            points_weighted=Coalesce(Sum(F("average_per_dart") * F("total_throws")), 0.0, output_field=FloatField()),
            best_avg=Coalesce(Max("average_per_round"), 0.0, output_field=FloatField()),
            sum_180=Coalesce(Sum("count_180s"), 0, output_field=FloatField()),
            sum_140=Coalesce(Sum("count_140_plus"), 0, output_field=FloatField()),
            sum_100=Coalesce(Sum("count_100_plus"), 0, output_field=FloatField()),
        )

        overall_avg = float(totals["points_weighted"] / totals["darts"]) if totals["darts"] else 0.0
        best_game_avg = float(totals["best_avg"])

        mode_breakdown = (
            player_qs.values("game__game_type")
            .annotate(count=Count("id"))
            .order_by("-count")
        )
        stats_by_mode = {item["game__game_type"]: item["count"] for item in mode_breakdown}

        recent = (
            player_qs.select_related("game")
            .order_by("-game__created_at")[:10]
        )
        recent_list = []
        for gp in recent:
            try:
                s = gp.detailed_stats
            except GameStatistics.DoesNotExist:
                s = None
            recent_list.append(
                {
                    "game_id": gp.game_id,
                    "game_type": gp.game.game_type,
                    "created_at": gp.game.created_at,
                    "result": "W" if gp.game.winner_id == user.id else "L",
                    "average_per_dart": float(s.average_per_dart) if s else None,
                    "checkout_percentage": float(s.checkout_percentage) if s else None,
                    "highest_score": s.highest_score if s else None,
                }
            )

        payload = {
            "total_games": total_games,
            "total_wins": wins,
            "total_losses": losses,
            "win_percentage": win_pct,
            "overall_average": round(overall_avg, 2),
            "best_game_average": round(best_game_avg, 2),
            "total_180s": totals["sum_180"],
            "total_140_plus": totals["sum_140"],
            "total_100_plus": totals["sum_100"],
            "stats_by_mode": stats_by_mode,
            "recent_form": recent_list,
        }

        # Include profile level and XP if available
        try:
            from accounts.models import UserProfile
            profile = UserProfile.objects.get(user=user)
            payload["level"] = profile.level
            payload["total_xp"] = profile.total_xp
        except UserProfile.DoesNotExist:
            pass

        return Response(payload, status=status.HTTP_200_OK)


class PersonalBestListView(APIView):
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get(self, request):
        qs = PersonalBest.objects.filter(user=request.user).order_by("-achieved_at")
        data = PersonalBestSerializer(qs, many=True).data
        return Response(data)


class AdminMetricsView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        now = timezone.now()
        day_ago = now - timedelta(days=1)
        week_ago = now - timedelta(days=7)

        def active_user_count(since):
            active_ids = set(
                AppUsageEvent.objects.filter(user__isnull=False, occurred_at__gte=since)
                .values_list("user_id", flat=True)
            )
            active_ids.update(
                Game.objects.filter(created_at__gte=since).values_list("created_by_id", flat=True)
            )
            active_ids.update(
                TrainingSession.objects.filter(created_at__gte=since).values_list("user_id", flat=True)
            )
            return len([user_id for user_id in active_ids if user_id])

        user_metrics = {
            "total": User.objects.count(),
            "new_last_24h": User.objects.filter(created_at__gte=day_ago).count(),
            "new_last_7d": User.objects.filter(created_at__gte=week_ago).count(),
            "active_last_24h": active_user_count(day_ago),
            "active_last_7d": active_user_count(week_ago),
        }

        usage_metrics = {
            "installs_total": AppUsageEvent.objects.filter(event_type=AppUsageEvent.EventType.INSTALL).count(),
            "installs_last_7d": AppUsageEvent.objects.filter(
                event_type=AppUsageEvent.EventType.INSTALL, occurred_at__gte=week_ago
            ).count(),
            "session_starts_last_24h": AppUsageEvent.objects.filter(
                event_type=AppUsageEvent.EventType.SESSION_START, occurred_at__gte=day_ago
            ).count(),
            "session_starts_last_7d": AppUsageEvent.objects.filter(
                event_type=AppUsageEvent.EventType.SESSION_START, occurred_at__gte=week_ago
            ).count(),
            "platform_breakdown_last_7d": {
                (item["platform"] or "unknown"): item["count"]
                for item in AppUsageEvent.objects.filter(
                    event_type=AppUsageEvent.EventType.INSTALL, occurred_at__gte=week_ago
                )
                .values("platform")
                .annotate(count=Count("id"))
            },
        }

        games_metrics = {
            "total": Game.objects.count(),
            "created_last_7d": Game.objects.filter(created_at__gte=week_ago).count(),
            "completed_last_7d": Game.objects.filter(
                status=Game.Status.COMPLETED, completed_at__gte=week_ago
            ).count(),
            "in_progress": Game.objects.filter(status=Game.Status.IN_PROGRESS).count(),
        }

        training_metrics = {
            "total": TrainingSession.objects.count(),
            "created_last_7d": TrainingSession.objects.filter(created_at__gte=week_ago).count(),
            "completed_last_7d": TrainingSession.objects.filter(
                status=TrainingSession.Status.COMPLETED, completed_at__gte=week_ago
            ).count(),
            "in_progress": TrainingSession.objects.filter(status=TrainingSession.Status.IN_PROGRESS).count(),
        }

        recent_events = [
            {
                "id": event.id,
                "event_type": event.event_type,
                "user_id": event.user_id,
                "platform": event.platform,
                "app_version": event.app_version,
                "occurred_at": event.occurred_at,
                "metadata": event.metadata,
            }
            for event in AppUsageEvent.objects.select_related("user").order_by("-occurred_at")[:25]
        ]

        payload = {
            "users": user_metrics,
            "usage": usage_metrics,
            "games": games_metrics,
            "training": training_metrics,
            "recent_events": recent_events,
        }

        return Response(payload, status=status.HTTP_200_OK)
