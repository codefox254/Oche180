from django.contrib import admin

from .models import (
    Tournament,
    TournamentEntry,
    TournamentRound,
    TournamentMatch,
    TournamentInvitation,
    PlayerTournamentRating,
    TournamentStanding,
    MatchScoreSubmission,
)


@admin.register(Tournament)
class TournamentAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "name",
        "tournament_format",
        "game_mode",
        "status",
        "organizer",
        "registration_start",
        "registration_end",
        "start_time",
    )
    search_fields = ("name", "organizer__email")
    list_filter = ("tournament_format", "game_mode", "status", "is_featured")
    date_hierarchy = "start_time"


@admin.register(TournamentEntry)
class TournamentEntryAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "tournament",
        "player",
        "status",
        "seed_number",
        "wins",
        "losses",
        "points",
        "registered_at",
    )
    search_fields = ("tournament__name", "player__email")
    list_filter = ("status",)
    date_hierarchy = "registered_at"


@admin.register(TournamentRound)
class TournamentRoundAdmin(admin.ModelAdmin):
    list_display = ("id", "tournament", "round_number", "name", "is_losers_bracket")
    search_fields = ("tournament__name", "name")
    list_filter = ("is_losers_bracket",)


@admin.register(TournamentMatch)
class TournamentMatchAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "tournament",
        "round",
        "match_number",
        "status",
        "player1_entry",
        "player2_entry",
        "winner_entry",
        "game",
    )
    search_fields = ("tournament__name", "round__name")
    list_filter = ("status",)


@admin.register(TournamentInvitation)
class TournamentInvitationAdmin(admin.ModelAdmin):
    list_display = ("id", "tournament", "player", "status", "invited_by", "created_at", "expires_at")
    search_fields = ("tournament__name", "player__email", "invited_by__email")
    list_filter = ("status",)
    date_hierarchy = "created_at"


@admin.register(PlayerTournamentRating)
class PlayerTournamentRatingAdmin(admin.ModelAdmin):
    list_display = (
        "player",
        "rating",
        "peak_rating",
        "tournaments_played",
        "tournaments_won",
        "total_matches_won",
        "total_matches_lost",
        "skill_tier",
        "last_tournament_date",
    )
    search_fields = ("player__email",)
    list_filter = ("skill_tier",)


@admin.register(TournamentStanding)
class TournamentStandingAdmin(admin.ModelAdmin):
    list_display = (
        "tournament",
        "entry",
        "rank",
        "matches_played",
        "matches_won",
        "matches_lost",
        "tournament_points",
        "points_difference",
    )
    search_fields = ("tournament__name", "entry__player__email")
    list_filter = ("tournament",)


@admin.register(MatchScoreSubmission)
class MatchScoreSubmissionAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "match",
        "submitted_by",
        "status",
        "submitted_at",
    )
    search_fields = ("match__tournament__name", "submitted_by__email")
    list_filter = ("status",)
    date_hierarchy = "submitted_at"
