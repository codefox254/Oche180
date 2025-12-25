from rest_framework import serializers
from .models import UserStatistics, PersonalBest


class UserStatisticsSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserStatistics
        fields = [
            "total_games",
            "total_wins",
            "total_losses",
            "win_percentage",
            "overall_average",
            "best_game_average",
            "total_180s",
            "total_140_plus",
            "total_100_plus",
            "stats_by_mode",
            "last_calculated",
        ]


class PersonalBestSerializer(serializers.ModelSerializer):
    class Meta:
        model = PersonalBest
        fields = ["id", "game_mode", "metric_name", "value", "achieved_at"]
        read_only_fields = fields
