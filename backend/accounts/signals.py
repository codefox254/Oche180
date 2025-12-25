from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from datetime import timedelta
from .models import User, UserProfile


@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    """Create UserProfile when User is created"""
    if created:
        UserProfile.objects.get_or_create(user=instance)


@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    """Save UserProfile when User is saved"""
    if hasattr(instance, 'profile'):
        instance.profile.save()


def update_user_streak(user):
    """Update user's daily streak on login"""
    profile = user.profile
    today = timezone.now().date()
    
    if profile.last_login_date is None:
        # First login ever
        profile.current_streak = 1
        profile.longest_streak = 1
    elif profile.last_login_date == today:
        # Already logged in today
        pass
    elif profile.last_login_date == today - timedelta(days=1):
        # Logged in yesterday - continue streak
        profile.current_streak += 1
        if profile.current_streak > profile.longest_streak:
            profile.longest_streak = profile.current_streak
    else:
        # Streak broken - reset
        profile.current_streak = 1
    
    profile.last_login_date = today
    profile.save()
