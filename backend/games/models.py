from django.db import models
from django.utils import timezone


class Game(models.Model):
    class GameType(models.TextChoices):
        FIVE_ZERO_ONE = "501", "501"
        THREE_ZERO_ONE = "301", "301"
        FOUR_ZERO_ONE = "401", "401"
        SEVEN_ZERO_ONE = "701", "701"
        ONE_ZERO_ZERO_ONE = "1001", "1001"
        CRICKET = "CRICKET", "Cricket"
        CRICKET_CUTTHROAT = "CRICKET_CUTTHROAT", "Cricket Cut-Throat"
        AROUND_THE_CLOCK = "ATC", "Around the Clock"
        SHANGHAI = "SHANGHAI", "Shanghai"
        KILLER = "KILLER", "Killer"
        HALVE_IT = "HALVE_IT", "Halve-It"
        BOBS_27 = "BOBS_27", "Bob's 27"
        SCRAM = "SCRAM", "Scram"
        TIC_TAC_TOE = "TIC_TAC_TOE", "Tic-Tac-Toe"
        ALL_FIVES = "ALL_FIVES", "All-Fives"
        MICKEY_MOUSE = "MICKEY_MOUSE", "Mickey Mouse"
        ENGLISH_CRICKET = "ENGLISH_CRICKET", "English Cricket"
        GOTCHA = "GOTCHA", "Gotcha"

    class Status(models.TextChoices):
        IN_PROGRESS = "IN_PROGRESS", "In Progress"
        COMPLETED = "COMPLETED", "Completed"
        ABANDONED = "ABANDONED", "Abandoned"

    game_type = models.CharField(max_length=20, choices=GameType.choices)
    created_by = models.ForeignKey("accounts.User", on_delete=models.CASCADE, related_name="created_games")
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.IN_PROGRESS)
    game_settings = models.JSONField(default=dict)  # starting_score, double_in, legs, sets
    winner = models.ForeignKey("accounts.User", on_delete=models.SET_NULL, null=True, blank=True, related_name="won_games")
    is_training = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["created_by", "-created_at"]),
            models.Index(fields=["status"]),
        ]

    def __str__(self):
        return f"{self.get_game_type_display()} - {self.created_by} ({self.get_status_display()})"

    def complete(self, winner=None):
        self.status = self.Status.COMPLETED
        self.completed_at = timezone.now()
        if winner:
            self.winner = winner
        self.save()


class GamePlayer(models.Model):
    game = models.ForeignKey(Game, on_delete=models.CASCADE, related_name="players")
    user = models.ForeignKey("accounts.User", on_delete=models.SET_NULL, null=True, blank=True)
    player_name = models.CharField(max_length=100)
    order = models.IntegerField()  # turn order
    final_score = models.IntegerField(default=0)
    final_position = models.IntegerField(null=True, blank=True)
    statistics = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["game", "order"]
        unique_together = ["game", "order"]

    def __str__(self):
        return f"{self.player_name} in {self.game}"


class Throw(models.Model):
    game = models.ForeignKey(Game, on_delete=models.CASCADE, related_name="throws")
    player = models.ForeignKey(GamePlayer, on_delete=models.CASCADE, related_name="throws")
    round_number = models.IntegerField()
    throw_number = models.IntegerField()  # 1, 2, or 3
    score = models.IntegerField()
    multiplier = models.IntegerField()  # 1=single, 2=double, 3=triple
    segment = models.IntegerField()  # 1-20 or 25 for bull
    is_bust = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["game", "round_number", "player__order", "throw_number"]
        indexes = [
            models.Index(fields=["game", "round_number"]),
            models.Index(fields=["player"]),
        ]

    def __str__(self):
        return f"R{self.round_number} T{self.throw_number} - {self.player.player_name}: {self.score}"


class GameStatistics(models.Model):
    game_player = models.OneToOneField(GamePlayer, on_delete=models.CASCADE, related_name="detailed_stats")
    total_throws = models.IntegerField(default=0)
    average_per_dart = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    average_per_round = models.DecimalField(max_digits=6, decimal_places=2, default=0)
    checkout_attempts = models.IntegerField(default=0)
    checkout_successes = models.IntegerField(default=0)
    checkout_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    count_180s = models.IntegerField(default=0)
    count_140_plus = models.IntegerField(default=0)
    count_100_plus = models.IntegerField(default=0)
    highest_score = models.IntegerField(default=0)
    marks_per_round = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)  # Cricket

    def __str__(self):
        return f"Stats for {self.game_player}"
