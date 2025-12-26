from django.contrib import admin

from .models import UserStatistics, PersonalBest, AppUsageEvent


@admin.register(UserStatistics)
class UserStatisticsAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "total_games",
        "total_wins",
        "total_losses",
        "win_percentage",
        "overall_average",
        "best_game_average",
        "last_calculated",
    )
    search_fields = ("user__email",)
    list_filter = ("last_calculated",)


@admin.register(PersonalBest)
class PersonalBestAdmin(admin.ModelAdmin):
    list_display = ("user", "game_mode", "metric_name", "value", "achieved_at")
    search_fields = ("user__email", "metric_name")
    list_filter = ("game_mode",)
    date_hierarchy = "achieved_at"


@admin.register(AppUsageEvent)
class AppUsageEventAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "event_type",
        "user",
        "platform",
        "app_version",
        "occurred_at",
    )
    list_filter = ("event_type", "platform", "occurred_at")
    search_fields = ("user__email", "app_version")
    date_hierarchy = "occurred_at"
