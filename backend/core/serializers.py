from rest_framework import serializers
from .models import AppSettings


class AppSettingsSerializer(serializers.ModelSerializer):
    """Serializer for AppSettings - public safe fields only"""
    
    class Meta:
        model = AppSettings
        fields = [
            'tournaments_enabled',
            'training_enabled',
            'multiplayer_enabled',
            'friend_requests_enabled',
            'leaderboards_enabled',
            'achievements_enabled',
            'chat_enabled',
            'maintenance_mode',
            'maintenance_message',
            'allow_new_registrations',
            'max_friends',
            'xp_multiplier',
            'daily_login_xp',
        ]
        read_only_fields = fields
