from django.contrib import admin

from .models import (
    TrainingSession,
    TrainingProgram,
    TrainingDrill,
    TrainingChallenge,
    TrainingThrow,
    TrainingPersonalBest,
)


@admin.register(TrainingSession)
class TrainingSessionAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "user",
        "mode",
        "status",
        "duration_minutes",
        "elapsed_seconds",
        "xp_earned",
        "created_at",
    )
    list_filter = ("mode", "status", "created_at")
    search_fields = ("user__email",)
    date_hierarchy = "created_at"


@admin.register(TrainingProgram)
class TrainingProgramAdmin(admin.ModelAdmin):
    list_display = ("id", "title", "level", "duration", "order", "updated_at")
    list_filter = ("level",)
    search_fields = ("title",)
    ordering = ("order",)


@admin.register(TrainingDrill)
class TrainingDrillAdmin(admin.ModelAdmin):
    list_display = ("id", "title", "category", "order", "updated_at")
    search_fields = ("title", "category")
    ordering = ("order",)


@admin.register(TrainingChallenge)
class TrainingChallengeAdmin(admin.ModelAdmin):
    list_display = ("id", "title", "difficulty", "reward", "order", "updated_at")
    search_fields = ("title", "difficulty")
    ordering = ("order",)


@admin.register(TrainingThrow)
class TrainingThrowAdmin(admin.ModelAdmin):
    list_display = ("id", "session", "throw_number", "target", "score", "hit", "created_at")
    list_filter = ("hit",)
    search_fields = ("session__id",)


@admin.register(TrainingPersonalBest)
class TrainingPersonalBestAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "mode", "value", "achieved_at")
    list_filter = ("mode",)
    search_fields = ("user__email",)
