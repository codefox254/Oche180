from rest_framework import serializers
from django.contrib.auth import get_user_model
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

User = get_user_model()


class TournamentEntrySerializer(serializers.ModelSerializer):
    """Serializer for tournament entries"""
    player_name = serializers.CharField(source="player.email", read_only=True)
    player_skill_level = serializers.CharField(source="player.skill_level", read_only=True)
    
    class Meta:
        model = TournamentEntry
        fields = [
            "id",
            "tournament",
            "player",
            "player_name",
            "player_skill_level",
            "status",
            "seed_number",
            "final_placement",
            "wins",
            "losses",
            "points",
            "tournament_points_earned",
            "rating_change",
            "total_score",
            "registered_at",
            "approved_at",
        ]
        read_only_fields = ["id", "wins", "losses", "points", "tournament_points_earned", 
                           "rating_change", "total_score", "registered_at", "approved_at"]


class TournamentMatchSerializer(serializers.ModelSerializer):
    """Serializer for tournament matches"""
    player1_name = serializers.CharField(source="player1_entry.player.email", read_only=True)
    player2_name = serializers.CharField(source="player2_entry.player.email", read_only=True)
    winner_name = serializers.CharField(source="winner_entry.player.email", read_only=True, allow_null=True)
    round_name = serializers.CharField(source="round.name", read_only=True)
    
    class Meta:
        model = TournamentMatch
        fields = [
            "id",
            "tournament",
            "round",
            "round_name",
            "player1_entry",
            "player1_name",
            "player2_entry",
            "player2_name",
            "match_number",
            "status",
            "winner_entry",
            "winner_name",
            "player1_score",
            "player2_score",
            "game",
            "scheduled_time",
            "started_at",
            "completed_at",
        ]
        read_only_fields = ["id", "started_at", "completed_at"]


class TournamentRoundSerializer(serializers.ModelSerializer):
    """Serializer for tournament rounds"""
    matches = TournamentMatchSerializer(many=True, read_only=True)
    
    class Meta:
        model = TournamentRound
        fields = [
            "id",
            "tournament",
            "round_number",
            "name",
            "is_losers_bracket",
            "started_at",
            "completed_at",
            "matches",
        ]
        read_only_fields = ["id", "started_at", "completed_at"]


class TournamentListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for tournament lists"""
    organizer_name = serializers.CharField(source="organizer.email", read_only=True)
    participant_count = serializers.IntegerField(read_only=True)
    spots_remaining = serializers.IntegerField(read_only=True)
    is_registration_open = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = Tournament
        fields = [
            "id",
            "name",
            "description",
            "organizer",
            "organizer_name",
            "tournament_format",
            "game_mode",
            "max_participants",
            "participant_count",
            "spots_remaining",
            "status",
            "registration_start",
            "registration_end",
            "start_time",
            "is_registration_open",
            "prize_pool",
            "is_featured",
            "banner_image",
            "created_at",
        ]


class TournamentDetailSerializer(serializers.ModelSerializer):
    """Full serializer for tournament details"""
    organizer_name = serializers.CharField(source="organizer.email", read_only=True)
    participant_count = serializers.IntegerField(read_only=True)
    spots_remaining = serializers.IntegerField(read_only=True)
    is_registration_open = serializers.BooleanField(read_only=True)
    entries = TournamentEntrySerializer(many=True, read_only=True)
    rounds = TournamentRoundSerializer(many=True, read_only=True)
    
    class Meta:
        model = Tournament
        fields = [
            "id",
            "name",
            "description",
            "organizer",
            "organizer_name",
            "tournament_format",
            "game_mode",
            "game_settings",
            "max_participants",
            "min_participants",
            "allow_public_registration",
            "require_approval",
            "registration_password",
            "min_skill_level",
            "registration_start",
            "registration_end",
            "start_time",
            "estimated_duration_hours",
            "status",
            "current_round",
            "prize_pool",
            "prize_description",
            "winner_xp_reward",
            "is_featured",
            "banner_image",
            "participant_count",
            "spots_remaining",
            "is_registration_open",
            "entries",
            "rounds",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "organizer", "status", "current_round", "created_at", "updated_at"]


class TournamentCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating tournaments"""
    
    class Meta:
        model = Tournament
        fields = [
            "name",
            "description",
            "tournament_format",
            "game_mode",
            "game_settings",
            "max_participants",
            "min_participants",
            "allow_public_registration",
            "require_approval",
            "registration_password",
            "min_skill_level",
            "registration_start",
            "registration_end",
            "start_time",
            "estimated_duration_hours",
            "prize_pool",
            "prize_description",
            "winner_xp_reward",
            "banner_image",
        ]
    
    def validate(self, data):
        """Validate tournament data"""
        if data["registration_end"] <= data["registration_start"]:
            raise serializers.ValidationError("Registration end must be after registration start")
        
        if data["start_time"] <= data["registration_end"]:
            raise serializers.ValidationError("Tournament start must be after registration ends")
        
        if data["max_participants"] < data["min_participants"]:
            raise serializers.ValidationError("Max participants must be >= min participants")
        
        return data

    def create(self, validated_data):
        """Ensure newly created tournaments start with registration open."""
        validated_data.setdefault("status", Tournament.Status.REGISTRATION_OPEN)
        return Tournament.objects.create(**validated_data)


class TournamentInvitationSerializer(serializers.ModelSerializer):
    """Serializer for tournament invitations"""
    tournament_name = serializers.CharField(source="tournament.name", read_only=True)
    player_name = serializers.CharField(source="player.email", read_only=True)
    invited_by_name = serializers.CharField(source="invited_by.email", read_only=True)
    
    class Meta:
        model = TournamentInvitation
        fields = [
            "id",
            "tournament",
            "tournament_name",
            "player",
            "player_name",
            "invited_by",
            "invited_by_name",
            "status",
            "message",
            "created_at",
            "responded_at",
            "expires_at",
        ]
        read_only_fields = ["id", "invited_by", "created_at", "responded_at"]


class BatchEntrySerializer(serializers.Serializer):
    """Serializer for batch adding players"""
    player_ids = serializers.ListField(
        child=serializers.IntegerField(),
        min_length=1,
        max_length=100
    )
    auto_approve = serializers.BooleanField(default=False)


class PlayerTournamentRatingSerializer(serializers.ModelSerializer):
    """Serializer for player tournament ratings"""
    player_name = serializers.CharField(source="player.email", read_only=True)
    win_rate = serializers.FloatField(read_only=True)
    
    class Meta:
        model = PlayerTournamentRating
        fields = [
            "id",
            "player",
            "player_name",
            "rating",
            "peak_rating",
            "lowest_rating",
            "tournaments_played",
            "tournaments_won",
            "tournaments_runner_up",
            "tournaments_top_4",
            "total_matches_won",
            "total_matches_lost",
            "win_rate",
            "total_tournament_points",
            "skill_tier",
            "last_tournament_date",
        ]
        read_only_fields = ["id", "player", "peak_rating", "lowest_rating"]


class TournamentStandingSerializer(serializers.ModelSerializer):
    """Serializer for tournament standings"""
    player_name = serializers.CharField(source="entry.player.email", read_only=True)
    player_id = serializers.IntegerField(source="entry.player.id", read_only=True)
    win_rate = serializers.FloatField(read_only=True)
    
    class Meta:
        model = TournamentStanding
        fields = [
            "id",
            "tournament",
            "entry",
            "player_id",
            "player_name",
            "rank",
            "matches_played",
            "matches_won",
            "matches_lost",
            "matches_drawn",
            "points_for",
            "points_against",
            "points_difference",
            "tournament_points",
            "average_score",
            "highest_score",
            "win_rate",
            "last_updated",
        ]
        read_only_fields = ["id", "last_updated"]


class MatchScoreSubmissionSerializer(serializers.ModelSerializer):
    """Serializer for match score submissions"""
    submitted_by_name = serializers.CharField(source="submitted_by.email", read_only=True)
    verified_by_name = serializers.CharField(source="verified_by.email", read_only=True, allow_null=True)
    match_details = TournamentMatchSerializer(source="match", read_only=True)
    
    class Meta:
        model = MatchScoreSubmission
        fields = [
            "id",
            "match",
            "match_details",
            "submitted_by",
            "submitted_by_name",
            "player1_score",
            "player2_score",
            "winner",
            "status",
            "verified_by",
            "verified_by_name",
            "notes",
            "passcode_used",
            "submitted_at",
            "verified_at",
        ]
        read_only_fields = ["id", "submitted_by", "verified_by", "submitted_at", "verified_at"]


class ScoreSubmissionCreateSerializer(serializers.Serializer):
    """Serializer for creating score submissions"""
    match_id = serializers.IntegerField()
    player1_score = serializers.IntegerField(min_value=0)
    player2_score = serializers.IntegerField(min_value=0)
    passcode = serializers.CharField(max_length=20)
    notes = serializers.CharField(required=False, allow_blank=True)

