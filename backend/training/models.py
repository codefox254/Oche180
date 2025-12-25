from django.db import models


class TrainingSession(models.Model):
    class Mode(models.TextChoices):
        PROGRAM = "PROGRAM", "Program"
        DRILL = "DRILL", "Drill"
        CHALLENGE = "CHALLENGE", "Challenge"
        BOBS_27 = "BOBS_27", "Bob's 27"
        CHECKOUT_PRACTICE = "CHECKOUT_PRACTICE", "Checkout Practice"
        FREE_PRACTICE = "FREE_PRACTICE", "Free Practice"
        OTHER = "OTHER", "Other"

    class Status(models.TextChoices):
        IN_PROGRESS = "IN_PROGRESS", "In Progress"
        COMPLETED = "COMPLETED", "Completed"

    user = models.ForeignKey("accounts.User", on_delete=models.CASCADE, related_name="training_sessions")
    mode = models.CharField(max_length=30, choices=Mode.choices)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.IN_PROGRESS)
    settings = models.JSONField(default=dict)  # includes customization: duration_minutes, target, difficulty
    duration_minutes = models.IntegerField(default=30, null=True, blank=True)  # Timer in minutes
    elapsed_seconds = models.IntegerField(default=0)  # How long user has been practicing
    final_score = models.IntegerField(null=True, blank=True)
    success_rate = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    xp_earned = models.IntegerField(default=0)  # XP earned in this session
    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user} - {self.get_mode_display()} ({self.get_status_display()})"


class TrainingProgram(models.Model):
    title = models.CharField(max_length=120)
    level = models.CharField(max_length=40, default="Intermediate")
    duration = models.CharField(max_length=40, default="30–45 min")
    description = models.TextField(blank=True)
    drills = models.JSONField(default=list)
    order = models.IntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["order", "id"]

    def __str__(self):
        return self.title


class TrainingDrill(models.Model):
    title = models.CharField(max_length=120)
    category = models.CharField(max_length=60, default="General")
    description = models.TextField(blank=True)
    order = models.IntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["order", "id"]

    def __str__(self):
        return self.title


class TrainingChallenge(models.Model):
    title = models.CharField(max_length=120)
    difficulty = models.CharField(max_length=40, default="Medium")
    reward = models.CharField(max_length=40, default="+50 XP")
    description = models.TextField(blank=True)
    order = models.IntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["order", "id"]

    def __str__(self):
        return self.title


class TrainingThrow(models.Model):
    session = models.ForeignKey(TrainingSession, on_delete=models.CASCADE, related_name="throws")
    throw_number = models.IntegerField()
    target = models.IntegerField()
    score = models.IntegerField()
    hit = models.BooleanField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["session", "throw_number"]

    def __str__(self):
        return f"Throw {self.throw_number} - Target: {self.target}, Score: {self.score}"


class TrainingPersonalBest(models.Model):
    user = models.ForeignKey("accounts.User", on_delete=models.CASCADE, related_name="training_personal_bests")
    mode = models.CharField(max_length=30)
    value = models.DecimalField(max_digits=10, decimal_places=2)
    achieved_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-value", "-achieved_at"]
        unique_together = ["user", "mode"]

    def __str__(self):
        return f"{self.user} - {self.mode}: {self.value}"
