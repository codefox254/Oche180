from django.contrib import admin
from .models import AppSettings


@admin.register(AppSettings)
class AppSettingsAdmin(admin.ModelAdmin):
    fieldsets = (
        ('Feature Toggles', {
            'fields': (
                'tournaments_enabled',
                'training_enabled',
                'multiplayer_enabled',
                'friend_requests_enabled',
                'leaderboards_enabled',
                'achievements_enabled',
                'chat_enabled',
            )
        }),
        ('Limits & Restrictions', {
            'fields': (
                'max_active_games_per_user',
                'max_tournaments_per_user',
                'max_tournament_participants',
                'max_friends',
                'max_games_per_day',
                'max_api_calls_per_minute',
            )
        }),
        ('Maintenance & Status', {
            'fields': (
                'maintenance_mode',
                'maintenance_message',
            )
        }),
        ('Registration & Security', {
            'fields': (
                'allow_new_registrations',
                'require_email_verification',
                'profanity_filter_enabled',
                'auto_moderate_usernames',
            )
        }),
        ('XP & Rewards', {
            'fields': (
                'xp_multiplier',
                'daily_login_xp',
            )
        }),
        ('Metadata', {
            'fields': ('updated_at', 'updated_by'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ('updated_at', 'updated_by')
    
    def has_add_permission(self, request):
        # Only allow one instance
        return not AppSettings.objects.exists()
    
    def has_delete_permission(self, request, obj=None):
        # Never allow deletion
        return False
    
    def save_model(self, request, obj, form, change):
        obj.updated_by = request.user
        super().save_model(request, obj, form, change)
