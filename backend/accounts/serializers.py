from rest_framework import serializers
from .models import User, UserProfile


class UserProfileSerializer(serializers.ModelSerializer):
    """Serializer for user profile with gamification stats"""
    
    class Meta:
        model = UserProfile
        fields = [
            "total_xp",
            "level",
            "current_streak",
            "longest_streak",
            "last_login_date",
            "total_training_sessions",
            "total_games_played",
        ]
        read_only_fields = [
            "total_xp",
            "level",
            "current_streak",
            "longest_streak",
            "last_login_date",
            "total_training_sessions",
            "total_games_played",
        ]


class UserSerializer(serializers.ModelSerializer):
    """Serializer for user with profile"""
    profile = UserProfileSerializer(read_only=True)
    
    class Meta:
        model = User
        fields = [
            "id",
            "email",
            "first_name",
            "last_name",
            "skill_level",
            "avatar",
            "profile",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]
