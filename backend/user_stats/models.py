from django.db import models


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
