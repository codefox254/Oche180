from django.db import models
from django.utils import timezone


class UserStatistics(models.Model):
    user = models.OneToOneField("accounts.User", on_delete=models.CASCADE, related_name="statistics")
    total_games = models.IntegerField(default=0)
    total_wins = models.IntegerField(default=0)
    total_losses = models.IntegerField(default=0)
    win_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    overall_average = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    best_game_average = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    total_180s = models.IntegerField(default=0)
    total_140_plus = models.IntegerField(default=0)
    total_100_plus = models.IntegerField(default=0)
    stats_by_mode = models.JSONField(default=dict)
    last_calculated = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "User statistics"

    def __str__(self):
        return f"Stats for {self.user}"


class PersonalBest(models.Model):
    user = models.ForeignKey("accounts.User", on_delete=models.CASCADE, related_name="personal_bests")
    game_mode = models.CharField(max_length=20)
    metric_name = models.CharField(max_length=100)
    value = models.DecimalField(max_digits=10, decimal_places=2)
    achieved_in_game = models.ForeignKey("games.Game", on_delete=models.SET_NULL, null=True, blank=True)
    achieved_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-achieved_at"]
        indexes = [
            models.Index(fields=["user", "game_mode"]),
        ]

    def __str__(self):
        return f"{self.user} - {self.metric_name}: {self.value}"


class AppUsageEvent(models.Model):
    class EventType(models.TextChoices):
        INSTALL = "INSTALL", "Install"
        SESSION_START = "SESSION_START", "Session Start"
        SESSION_END = "SESSION_END", "Session End"
        SCREEN_VIEW = "SCREEN_VIEW", "Screen View"
        ACTION = "ACTION", "Action"

    user = models.ForeignKey("accounts.User", on_delete=models.SET_NULL, null=True, blank=True, related_name="usage_events")
    event_type = models.CharField(max_length=30, choices=EventType.choices)
    platform = models.CharField(max_length=30, blank=True)
    app_version = models.CharField(max_length=30, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    occurred_at = models.DateTimeField(default=timezone.now, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-occurred_at", "-id"]
        indexes = [
            models.Index(fields=["event_type", "-occurred_at"]),
            models.Index(fields=["platform", "-occurred_at"]),
        ]

    def __str__(self):
        return f"{self.get_event_type_display()} @ {self.occurred_at:%Y-%m-%d %H:%M:%S}"
