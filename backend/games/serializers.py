from rest_framework import serializers

from .models import Game, GamePlayer, GameStatistics, Throw


class ThrowSerializer(serializers.ModelSerializer):
    class Meta:
        model = Throw
        fields = [
            "id",
            "round_number",
            "throw_number",
            "score",
            "multiplier",
            "segment",
            "is_bust",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class GameStatisticsSerializer(serializers.ModelSerializer):
    class Meta:
        model = GameStatistics
        fields = "__all__"


class GamePlayerSerializer(serializers.ModelSerializer):
    user_email = serializers.EmailField(source="user.email", read_only=True)
    detailed_stats = GameStatisticsSerializer(read_only=True)

    class Meta:
        model = GamePlayer
        fields = [
            "id",
            "user",
            "user_email",
            "player_name",
            "order",
            "final_score",
            "final_position",
            "statistics",
            "detailed_stats",
        ]


class GameSerializer(serializers.ModelSerializer):
    players = GamePlayerSerializer(many=True, read_only=True)
    created_by_email = serializers.EmailField(source="created_by.email", read_only=True)

    class Meta:
        model = Game
        fields = [
            "id",
            "game_type",
            "created_by",
            "created_by_email",
            "status",
            "game_settings",
            "winner",
            "is_training",
            "created_at",
            "completed_at",
            "players",
        ]
        read_only_fields = ["id", "created_at", "completed_at"]


class CreateGameSerializer(serializers.Serializer):
    game_type = serializers.ChoiceField(choices=Game.GameType.choices)
    game_settings = serializers.JSONField(default=dict)
    players = serializers.ListField(
        child=serializers.DictField(),
        min_length=1,
        max_length=4,
    )

    def create(self, validated_data):
        user = self.context["request"].user
        players_data = validated_data.pop("players")

        game = Game.objects.create(
            created_by=user,
            game_type=validated_data["game_type"],
            game_settings=validated_data.get("game_settings", {}),
        )

        for idx, player_data in enumerate(players_data):
            GamePlayer.objects.create(
                game=game,
                user=user if player_data.get("is_current_user") else None,
                player_name=player_data.get("name", f"Player {idx + 1}"),
                order=idx,
            )

        return game
