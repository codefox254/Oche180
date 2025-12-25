from rest_framework import serializers
from .models import (
    TrainingSession,
    TrainingThrow,
    TrainingPersonalBest,
    TrainingProgram,
    TrainingDrill,
    TrainingChallenge,
)


class TrainingThrowSerializer(serializers.ModelSerializer):
    class Meta:
        model = TrainingThrow
        fields = ["id", "session", "throw_number", "target", "score", "hit", "created_at"]
        read_only_fields = ["id", "created_at"]


class TrainingSessionSerializer(serializers.ModelSerializer):
    throws = TrainingThrowSerializer(many=True, read_only=True)

    class Meta:
        model = TrainingSession
        fields = [
            "id",
            "user",
            "mode",
            "status",
            "settings",
            "final_score",
            "success_rate",
            "created_at",
            "completed_at",
            "throws",
        ]
        read_only_fields = ["id", "user", "created_at", "completed_at"]


class TrainingPersonalBestSerializer(serializers.ModelSerializer):
    class Meta:
        model = TrainingPersonalBest
        fields = ["id", "user", "mode", "value", "achieved_at"]
        read_only_fields = ["id", "user", "achieved_at"]


class TrainingProgramSerializer(serializers.ModelSerializer):
    class Meta:
        model = TrainingProgram
        fields = ["id", "title", "level", "duration", "description", "drills", "order", "updated_at"]
        read_only_fields = ["id", "updated_at"]


class TrainingDrillSerializer(serializers.ModelSerializer):
    class Meta:
        model = TrainingDrill
        fields = ["id", "title", "category", "description", "order", "updated_at"]
        read_only_fields = ["id", "updated_at"]


class TrainingChallengeSerializer(serializers.ModelSerializer):
    class Meta:
        model = TrainingChallenge
        fields = ["id", "title", "difficulty", "reward", "description", "order", "updated_at"]
        read_only_fields = ["id", "updated_at"]
