from django.db.models import F, Sum, Count, Max
from django.db.models.functions import Coalesce
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from games.models import Game, GamePlayer, GameStatistics
from .models import UserStatistics, PersonalBest
from .serializers import UserStatisticsSerializer, PersonalBestSerializer


class StatsSummaryView(APIView):
    permission_classes = [permissions.IsAuthenticated]

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
            darts=Coalesce(Sum("total_throws"), 0),
            points_weighted=Coalesce(Sum(F("average_per_dart") * F("total_throws")), 0.0),
            best_avg=Coalesce(Max("average_per_round"), 0.0),
            sum_180=Coalesce(Sum("count_180s"), 0),
            sum_140=Coalesce(Sum("count_140_plus"), 0),
            sum_100=Coalesce(Sum("count_100_plus"), 0),
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

        return Response(payload, status=status.HTTP_200_OK)


class PersonalBestListView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        qs = PersonalBest.objects.filter(user=request.user).order_by("-achieved_at")
        data = PersonalBestSerializer(qs, many=True).data
        return Response(data)
