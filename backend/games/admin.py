from django.contrib import admin

from .models import Game, GamePlayer, Throw, GameStatistics


@admin.register(Game)
class GameAdmin(admin.ModelAdmin):
    list_display = ("id", "game_type", "status", "created_by", "winner", "created_at")
    list_filter = ("game_type", "status", "is_training", "created_at")
    search_fields = ("id", "created_by__email", "winner__email")
    date_hierarchy = "created_at"


@admin.register(GamePlayer)
class GamePlayerAdmin(admin.ModelAdmin):
    list_display = ("id", "game", "player_name", "user", "order", "final_score", "final_position")
    list_filter = ("game__game_type",)
    search_fields = ("player_name", "user__email", "game__id")


@admin.register(Throw)
class ThrowAdmin(admin.ModelAdmin):
    list_display = ("id", "game", "player", "round_number", "throw_number", "score", "multiplier", "segment")
    list_filter = ("round_number", "multiplier")
    search_fields = ("player__player_name", "game__id")


@admin.register(GameStatistics)
class GameStatisticsAdmin(admin.ModelAdmin):
    list_display = (
        "game_player",
        "total_throws",
        "average_per_dart",
        "average_per_round",
        "checkout_percentage",
        "count_180s",
        "count_140_plus",
        "count_100_plus",
        "highest_score",
    )
    search_fields = ("game_player__player_name", "game_player__game__id")
