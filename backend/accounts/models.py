from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.core.validators import RegexValidator, MinLengthValidator
from django.db import models


class UserManager(BaseUserManager):
    use_in_migrations = True

    def _create_user(self, email: str, password: str | None, **extra_fields):
        if not email:
            raise ValueError("The email address must be set")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, email: str, password: str | None = None, **extra_fields):
        extra_fields.setdefault("is_staff", False)
        extra_fields.setdefault("is_superuser", False)
        return self._create_user(email, password, **extra_fields)

    def create_superuser(self, email: str, password: str, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)

        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")

        return self._create_user(email, password, **extra_fields)


class User(AbstractUser):
    class SkillLevel(models.TextChoices):
        BEGINNER = "BEGINNER", "Beginner"
        INTERMEDIATE = "INTERMEDIATE", "Intermediate"
        ADVANCED = "ADVANCED", "Advanced"
        PROFESSIONAL = "PROFESSIONAL", "Professional"

    username = None
    email = models.EmailField(unique=True)
    # Public handle: 6+ chars, letters/numbers/underscore only
    public_username = models.CharField(
        max_length=30,
        unique=True,
        validators=[
            MinLengthValidator(6),
            RegexValidator(
                regex=r"^[A-Za-z0-9_]+$",
                message="Username must be letters, numbers or underscore",
            ),
        ],
        help_text=(
            "Unique username (6+ chars). Letters, numbers, underscore only."
        ),
        null=True,
        blank=True,
    )
    avatar = models.ImageField(upload_to="avatars/", null=True, blank=True)
    skill_level = models.CharField(
        max_length=20, choices=SkillLevel.choices, default=SkillLevel.BEGINNER
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS: list[str] = []

    objects = UserManager()

    def __str__(self) -> str:  # pragma: no cover - trivial representation
        return self.public_username or self.email or "User"


class UserProfile(models.Model):
    """Extended user profile with gamification features: streaks, XP, levels"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="profile")
    
    # Gamification
    total_xp = models.IntegerField(default=0)
    level = models.IntegerField(default=1)
    
    # Streak tracking
    current_streak = models.IntegerField(default=0)  # Days in a row
    longest_streak = models.IntegerField(default=0)
    last_login_date = models.DateField(null=True, blank=True)
    
    # Stats
    total_training_sessions = models.IntegerField(default=0)
    total_games_played = models.IntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.user.email} - Level {self.level} ({self.total_xp} XP)"
