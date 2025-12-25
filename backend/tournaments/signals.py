from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Tournament, TournamentEntry


@receiver(post_save, sender=TournamentEntry)
def update_tournament_status(sender, instance, created, **kwargs):
    """Auto-update tournament status when capacity is reached"""
    if not created:
        return
    
    tournament = instance.tournament
    
    if tournament.status == Tournament.Status.REGISTRATION_OPEN:
        confirmed_count = tournament.entries.filter(status=TournamentEntry.Status.CONFIRMED).count()
        
        # Auto-close registration when full
        if confirmed_count >= tournament.max_participants:
            tournament.status = Tournament.Status.REGISTRATION_CLOSED
            tournament.save()
