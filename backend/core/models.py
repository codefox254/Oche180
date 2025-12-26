from django.db import models
from django.core.cache import cache


class AppSettings(models.Model):
    """Global app settings and feature flags controlled by admin"""
    
    # Singleton pattern - only one instance should exist
    singleton_id = models.BooleanField(default=True, unique=True, editable=False)
    
    # Feature Flags
    tournaments_enabled = models.BooleanField(default=True, help_text="Enable tournament features")
    training_enabled = models.BooleanField(default=True, help_text="Enable training features")
    multiplayer_enabled = models.BooleanField(default=True, help_text="Enable multiplayer games")
    friend_requests_enabled = models.BooleanField(default=True, help_text="Enable friend system")
    leaderboards_enabled = models.BooleanField(default=True, help_text="Enable global leaderboards")
    achievements_enabled = models.BooleanField(default=True, help_text="Enable achievements system")
    
    # Limits
    max_active_games_per_user = models.IntegerField(default=10, help_text="Maximum concurrent active games")
    max_tournaments_per_user = models.IntegerField(default=5, help_text="Maximum tournaments a user can organize")
    max_tournament_participants = models.IntegerField(default=128, help_text="Global maximum tournament size")
    
    # Maintenance
    maintenance_mode = models.BooleanField(default=False, help_text="Enable maintenance mode")
    maintenance_message = models.TextField(
        blank=True,
        default="Oche180 is currently undergoing maintenance. Please check back soon!"
    )
    
    # Registration Controls
    allow_new_registrations = models.BooleanField(default=True, help_text="Allow new user signups")
    require_email_verification = models.BooleanField(default=False, help_text="Require email verification for new accounts")
    
    # Content Moderation
    profanity_filter_enabled = models.BooleanField(default=True, help_text="Enable profanity filtering in user-generated content")
    auto_moderate_usernames = models.BooleanField(default=True, help_text="Automatically check usernames for inappropriate content")
    
    # Social Features
    chat_enabled = models.BooleanField(default=False, help_text="Enable in-app chat")
    max_friends = models.IntegerField(default=100, help_text="Maximum friends per user")
    
    # XP & Rewards
    xp_multiplier = models.DecimalField(
        max_digits=3, 
        decimal_places=2, 
        default=1.00,
        help_text="Global XP multiplier (e.g., 1.5 for 50% bonus)"
    )
    daily_login_xp = models.IntegerField(default=10, help_text="XP awarded for daily login")
    
    # Rate Limiting
    max_games_per_day = models.IntegerField(default=100, help_text="Maximum games per user per day (0 = unlimited)")
    max_api_calls_per_minute = models.IntegerField(default=60, help_text="API rate limit per user")
    
    # Meta
    updated_at = models.DateTimeField(auto_now=True)
    updated_by = models.ForeignKey(
        'accounts.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='app_settings_updates'
    )
    
    class Meta:
        verbose_name = "App Settings"
        verbose_name_plural = "App Settings"
    
    def __str__(self):
        return "App Settings"
    
    def save(self, *args, **kwargs):
        # Ensure only one instance exists
        if not self.pk and AppSettings.objects.exists():
            raise ValueError("Only one AppSettings instance can exist")
        
        super().save(*args, **kwargs)
        
        # Clear cache when settings are updated
        cache.delete('app_settings')
    
    @classmethod
    def get_settings(cls):
        """Get the singleton settings instance with caching"""
        settings = cache.get('app_settings')
        
        if not settings:
            settings, created = cls.objects.get_or_create(
                singleton_id=True,
                defaults={}
            )
            cache.set('app_settings', settings, 300)  # Cache for 5 minutes
        
        return settings
    
    @classmethod
    def is_feature_enabled(cls, feature_name):
        """Check if a feature is enabled"""
        settings = cls.get_settings()
        return getattr(settings, f"{feature_name}_enabled", True)
