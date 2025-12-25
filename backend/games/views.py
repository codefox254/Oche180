from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Game, GamePlayer, Throw
from .serializers import CreateGameSerializer, GameSerializer, ThrowSerializer


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
            stats[player.player_name] = player.statistics
        return Response(stats)

    @action(detail=False, methods=["get"])
    def recent(self, request):
        games = self.get_queryset()[:10]
        serializer = self.get_serializer(games, many=True)
        return Response(serializer.data)
