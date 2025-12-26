from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.utils import timezone
from decimal import Decimal

from .models import Game, GamePlayer, Throw, GameStatistics
from .serializers import CreateGameSerializer, GameSerializer, ThrowSerializer
from user_stats.models import UserStatistics
from accounts.models import UserProfile


class GameViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = GameSerializer
    
    def get_queryset(self):
        return Game.objects.filter(created_by=self.request.user).prefetch_related("players", "throws")

    def get_serializer_class(self):
        if self.action == "create":
            return CreateGameSerializer
        return GameSerializer

    @action(detail=True, methods=["post"])
    def record_throw(self, request, pk=None):
        game = self.get_object()
        
        if game.status != Game.Status.IN_PROGRESS:
            return Response(
                {"error": "Game is not in progress"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = ThrowSerializer(data=request.data)
        if serializer.is_valid():
            player_id = request.data.get("player_id")
            try:
                player = game.players.get(id=player_id)
            except GamePlayer.DoesNotExist:
                return Response(
                    {"error": "Player not found"},
                    status=status.HTTP_404_NOT_FOUND,
                )

            throw = serializer.save(game=game, player=player)
            return Response(ThrowSerializer(throw).data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=["post"])
    def submit_game_result(self, request):
        """
        Submit game result with comprehensive statistics.
        Records game outcome, updates user statistics, and calculates averages.
        """
        game_data = request.data
        user = request.user
        
        try:
            # Create game
            game = Game.objects.create(
                created_by=user,
                game_type=game_data.get('game_type'),
                game_settings=game_data.get('game_settings', {}),
                is_training=game_data.get('is_training', False),
                status=Game.Status.COMPLETED,
                completed_at=timezone.now(),
            )
            
            # Process players and their statistics
            players_data = game_data.get('players', [])
            winner = None
            
            for idx, player_info in enumerate(players_data):
                player = GamePlayer.objects.create(
                    game=game,
                    user=user if player_info.get('is_current_user') else None,
                    player_name=player_info.get('name', f'Player {idx + 1}'),
                    order=idx,
                    final_score=player_info.get('final_score', 0),
                    final_position=player_info.get('final_position'),
                    statistics=player_info.get('statistics', {}),
                )
                
                # Create detailed statistics
                stats_info = player_info.get('detailed_stats', {})
                detailed_stats = GameStatistics.objects.create(
                    game_player=player,
                    total_throws=stats_info.get('total_throws', 0),
                    average_per_dart=Decimal(stats_info.get('average_per_dart', 0)),
                    average_per_round=Decimal(stats_info.get('average_per_round', 0)),
                    checkout_attempts=stats_info.get('checkout_attempts', 0),
                    checkout_successes=stats_info.get('checkout_successes', 0),
                    checkout_percentage=Decimal(stats_info.get('checkout_percentage', 0)),
                    count_180s=stats_info.get('count_180s', 0),
                    count_140_plus=stats_info.get('count_140_plus', 0),
                    count_100_plus=stats_info.get('count_100_plus', 0),
                    highest_score=stats_info.get('highest_score', 0),
                    marks_per_round=Decimal(stats_info.get('marks_per_round', 0)) if stats_info.get('marks_per_round') else None,
                )
                
                # Set winner if this player won
                if player_info.get('is_winner'):
                    winner = user
                    player.final_position = 1
                    player.save()
            
            # Mark game winner
            if winner:
                game.winner = winner
                game.save()
            
            # Update user statistics (only for training or if user is in game)
            if user in [p.user for p in game.players.all() if p.user]:
                update_user_statistics(user, game, players_data)
            
            return Response({
                'game_id': game.id,
                'message': 'Game result recorded successfully',
                'statistics': get_game_result_summary(game, players_data)
            }, status=status.HTTP_201_CREATED)
        
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

    @action(detail=True, methods=["post"])
    def complete(self, request, pk=None):
        game = self.get_object()
        winner_id = request.data.get("winner_id")
        
        if winner_id:
            try:
                player = game.players.get(id=winner_id)
                game.complete(winner=player.user)
            except GamePlayer.DoesNotExist:
                return Response(
                    {"error": "Winner not found"},
                    status=status.HTTP_404_NOT_FOUND,
                )
        else:
            game.complete()

        return Response(GameSerializer(game).data)

    @action(detail=True, methods=["get"])
    def statistics(self, request, pk=None):
        game = self.get_object()
        stats = {}
        for player in game.players.all():
            stats[player.player_name] = {
                'statistics': player.statistics,
                'detailed_stats': player.detailed_stats.__dict__ if hasattr(player, 'detailed_stats') else None
            }
        return Response(stats)

    @action(detail=False, methods=["get"])
    def recent(self, request):
        games = self.get_queryset()[:10]
        serializer = self.get_serializer(games, many=True)
        return Response(serializer.data)


def update_user_statistics(user, game, players_data):
    """Update user statistics after game completion"""
    try:
        stats, _ = UserStatistics.objects.get_or_create(user=user)
        profile, _ = UserProfile.objects.get_or_create(user=user)
        
        # Find current user's result in the game
        current_player_data = None
        is_winner = False
        player_average = 0
        
        for p_data in players_data:
            if p_data.get('is_current_user'):
                current_player_data = p_data
                is_winner = p_data.get('is_winner', False)
                player_average = Decimal(p_data.get('detailed_stats', {}).get('average_per_dart', 0))
                break
        
        if current_player_data:
            # Update game counts
            stats.total_games += 1
            if is_winner:
                stats.total_wins += 1
                profile.total_xp += 100  # Award XP for win
            else:
                stats.total_losses += 1
                profile.total_xp += 25  # Award XP for participation
            
            # Update win percentage
            if stats.total_games > 0:
                stats.win_percentage = (Decimal(stats.total_wins) / Decimal(stats.total_games)) * 100
            
            # Update averages
            detailed_stats = current_player_data.get('detailed_stats', {})
            count_180s = detailed_stats.get('count_180s', 0)
            count_140_plus = detailed_stats.get('count_140_plus', 0)
            count_100_plus = detailed_stats.get('count_100_plus', 0)
            
            # Recalculate overall average (weighted average)
            if player_average > 0:
                if stats.best_game_average == 0 or player_average > stats.best_game_average:
                    stats.best_game_average = player_average
                
                # Update overall average (simple average for now)
                total_darts = detailed_stats.get('total_throws', 0)
                if total_darts > 0:
                    current_total = Decimal(stats.overall_average) * Decimal(stats.total_games - 1) if stats.total_games > 1 else Decimal(0)
                    stats.overall_average = (current_total + player_average) / Decimal(stats.total_games)
            
            # Update high score counts
            stats.total_180s += count_180s
            stats.total_140_plus += count_140_plus
            stats.total_100_plus += count_100_plus
            
            # Update stats by game mode
            if not stats.stats_by_mode:
                stats.stats_by_mode = {}
            
            game_mode = game.game_type
            if game_mode not in stats.stats_by_mode:
                stats.stats_by_mode[game_mode] = {
                    'games': 0,
                    'wins': 0,
                    'average': 0,
                    'best_average': 0,
                }
            
            mode_stats = stats.stats_by_mode[game_mode]
            mode_stats['games'] += 1
            if is_winner:
                mode_stats['wins'] += 1
            
            if player_average > 0:
                if float(mode_stats['best_average']) == 0 or player_average > Decimal(mode_stats['best_average']):
                    mode_stats['best_average'] = float(player_average)
                
                mode_games = mode_stats['games']
                current_mode_avg = Decimal(mode_stats['average']) * Decimal(mode_games - 1) if mode_games > 1 else Decimal(0)
                mode_stats['average'] = float((current_mode_avg + player_average) / Decimal(mode_games))
            
            stats.save()
            profile.save()
    
    except Exception as e:
        print(f"Error updating user statistics: {e}")


def get_game_result_summary(game, players_data):
    """Generate comprehensive game result summary"""
    summary = {
        'game_type': game.get_game_type_display(),
        'is_training': game.is_training,
        'completed_at': game.completed_at,
        'players_results': []
    }
    
    for p_data in players_data:
        detailed_stats = p_data.get('detailed_stats', {})
        summary['players_results'].append({
            'name': p_data.get('name'),
            'final_score': p_data.get('final_score'),
            'final_position': p_data.get('final_position'),
            'is_winner': p_data.get('is_winner', False),
            'average_per_dart': detailed_stats.get('average_per_dart', 0),
            'average_per_round': detailed_stats.get('average_per_round', 0),
            'total_throws': detailed_stats.get('total_throws', 0),
            'count_180s': detailed_stats.get('count_180s', 0),
            'count_140_plus': detailed_stats.get('count_140_plus', 0),
            'count_100_plus': detailed_stats.get('count_100_plus', 0),
            'highest_score': detailed_stats.get('highest_score', 0),
            'checkout_percentage': detailed_stats.get('checkout_percentage', 0),
        })
    
    return summary
