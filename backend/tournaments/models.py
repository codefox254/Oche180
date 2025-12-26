from django.db import models
from django.utils import timezone
from django.core.validators import MinValueValidator, MaxValueValidator


class Tournament(models.Model):
    """Main tournament model supporting multiple formats"""
    
    class Format(models.TextChoices):
        SINGLE_ELIMINATION = "SINGLE_ELIM", "Single Elimination"
        DOUBLE_ELIMINATION = "DOUBLE_ELIM", "Double Elimination"
        ROUND_ROBIN = "ROUND_ROBIN", "Round Robin"
        SWISS = "SWISS", "Swiss System"
        GROUPS_KNOCKOUT = "GROUPS_KO", "Groups + Knockout"
        LADDER = "LADDER", "Ladder"
        FREE_FOR_ALL = "FFA", "Free-for-All"
    
    class Status(models.TextChoices):
        DRAFT = "DRAFT", "Draft"
        REGISTRATION_OPEN = "REG_OPEN", "Registration Open"
        REGISTRATION_CLOSED = "REG_CLOSED", "Registration Closed"
        IN_PROGRESS = "IN_PROGRESS", "In Progress"
        COMPLETED = "COMPLETED", "Completed"
        CANCELLED = "CANCELLED", "Cancelled"
    
    class GameMode(models.TextChoices):
        FIVE_ZERO_ONE = "501", "501"
        THREE_ZERO_ONE = "301", "301"
        CRICKET = "CRICKET", "Cricket"
        AROUND_THE_CLOCK = "ATC", "Around the Clock"
        CUSTOM = "CUSTOM", "Custom"
    
    # Basic Info
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    organizer = models.ForeignKey("accounts.User", on_delete=models.CASCADE, related_name="organized_tournaments")
    
    # Tournament Settings
    tournament_format = models.CharField(max_length=20, choices=Format.choices, default=Format.SINGLE_ELIMINATION)
    game_mode = models.CharField(max_length=20, choices=GameMode.choices, default=GameMode.FIVE_ZERO_ONE)
    game_settings = models.JSONField(default=dict)  # legs, sets, double-in/out, etc.
    
    # Entry Management
    max_participants = models.IntegerField(default=32, validators=[MinValueValidator(2), MaxValueValidator(512)])
    min_participants = models.IntegerField(default=4, validators=[MinValueValidator(2)])
    is_private = models.BooleanField(default=False, help_text="Private tournaments are hidden from public listing")
    allow_public_registration = models.BooleanField(default=True)
    require_approval = models.BooleanField(default=False)  # Organizer must approve entries
    registration_password = models.CharField(max_length=100, blank=True)  # Optional password protection
    
    # Skill Restrictions
    min_skill_level = models.CharField(max_length=20, blank=True, choices=[
        ("", "No Restriction"),
        ("BEGINNER", "Beginner+"),
        ("INTERMEDIATE", "Intermediate+"),
        ("ADVANCED", "Advanced+"),
        ("PROFESSIONAL", "Professional Only"),
    ])
    
    # Timing
    registration_start = models.DateTimeField()
    registration_end = models.DateTimeField()
    start_time = models.DateTimeField()
    estimated_duration_hours = models.IntegerField(default=2)
    
    # Status
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.DRAFT)
    current_round = models.IntegerField(default=0)
    
    # Prize & Rewards
    prize_pool = models.DecimalField(max_digits=10, decimal_places=2, default=0, blank=True)
    prize_description = models.TextField(blank=True)
    winner_xp_reward = models.IntegerField(default=500)
    
    # Meta
    is_featured = models.BooleanField(default=False)
    banner_image = models.ImageField(upload_to="tournament_banners/", null=True, blank=True)
    
    # Score Submission
    score_passcode = models.CharField(max_length=20, blank=True, help_text="Passcode for participants to submit scores")
    allow_score_submission = models.BooleanField(default=True, help_text="Allow participants to submit match scores")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ["-start_time"]
        indexes = [
            models.Index(fields=["status", "-start_time"]),
            models.Index(fields=["organizer", "-created_at"]),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.get_tournament_format_display()})"
    
    @property
    def is_registration_open(self):
        now = timezone.now()
        return (
            self.status == self.Status.REGISTRATION_OPEN
            and self.registration_start <= now <= self.registration_end
            and self.entries.filter(status=TournamentEntry.Status.CONFIRMED).count() < self.max_participants
        )
    
    @property
    def participant_count(self):
        return self.entries.filter(status=TournamentEntry.Status.CONFIRMED).count()
    
    @property
    def spots_remaining(self):
        return max(0, self.max_participants - self.participant_count)
    
    def verify_passcode(self, passcode):
        """Verify if the provided passcode is correct"""
        if not self.score_passcode:
            return True  # No passcode required
        return self.score_passcode == passcode
    
    def generate_passcode(self):
        """Generate a random 6-digit passcode"""
        import random
        self.score_passcode = ''.join([str(random.randint(0, 9)) for _ in range(6)])
        return self.score_passcode


class TournamentEntry(models.Model):
    """Player entry/registration for a tournament"""
    
    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending Approval"
        CONFIRMED = "CONFIRMED", "Confirmed"
        DECLINED = "DECLINED", "Declined"
        WITHDRAWN = "WITHDRAWN", "Withdrawn"
        DISQUALIFIED = "DISQUALIFIED", "Disqualified"
    
    tournament = models.ForeignKey(Tournament, on_delete=models.CASCADE, related_name="entries")
    player = models.ForeignKey("accounts.User", on_delete=models.CASCADE, related_name="tournament_entries")
    
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    
    # Seeding & Placement
    seed_number = models.IntegerField(null=True, blank=True)  # For seeded tournaments
    final_placement = models.IntegerField(null=True, blank=True)  # 1st, 2nd, 3rd, etc.
    
    # Stats
    wins = models.IntegerField(default=0)
    losses = models.IntegerField(default=0)
    points = models.IntegerField(default=0)  # For Swiss/Round-robin
    
    # Performance & Rating
    tournament_points_earned = models.IntegerField(default=0, help_text="Points earned based on placement")
    rating_change = models.IntegerField(default=0, help_text="Rating change from this tournament")
    total_score = models.IntegerField(default=0, help_text="Total points scored across all matches")
    
    # Meta
    registered_at = models.DateTimeField(auto_now_add=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        unique_together = ["tournament", "player"]
        ordering = ["seed_number", "-points", "-wins", "registered_at"]
    
    def __str__(self):
        return f"{self.player} in {self.tournament.name} ({self.get_status_display()})"


class TournamentRound(models.Model):
    """Represents a round in the tournament (e.g., Round of 16, Quarterfinals)"""
    
    tournament = models.ForeignKey(Tournament, on_delete=models.CASCADE, related_name="rounds")
    round_number = models.IntegerField()  # 1, 2, 3... or -1 for finals, -2 for semifinals
    name = models.CharField(max_length=100)  # "Round of 16", "Quarterfinals", "Finals"
    
    is_losers_bracket = models.BooleanField(default=False)  # For double elimination
    
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        unique_together = ["tournament", "round_number", "is_losers_bracket"]
        ordering = ["tournament", "is_losers_bracket", "round_number"]
    
    def __str__(self):
        bracket = " (Losers)" if self.is_losers_bracket else ""
        return f"{self.tournament.name} - {self.name}{bracket}"


class TournamentMatch(models.Model):
    """Individual match within a tournament"""
    
    class Status(models.TextChoices):
        SCHEDULED = "SCHEDULED", "Scheduled"
        IN_PROGRESS = "IN_PROGRESS", "In Progress"
        COMPLETED = "COMPLETED", "Completed"
        WALKOVER = "WALKOVER", "Walkover"
        CANCELLED = "CANCELLED", "Cancelled"
    
    tournament = models.ForeignKey(Tournament, on_delete=models.CASCADE, related_name="matches")
    round = models.ForeignKey(TournamentRound, on_delete=models.CASCADE, related_name="matches")
    
    # Match participants
    player1_entry = models.ForeignKey(TournamentEntry, on_delete=models.SET_NULL, null=True, blank=True, related_name="matches_as_player1")
    player2_entry = models.ForeignKey(TournamentEntry, on_delete=models.SET_NULL, null=True, blank=True, related_name="matches_as_player2")
    
    # Bracket position
    match_number = models.IntegerField()  # Position in bracket
    next_match = models.ForeignKey("self", on_delete=models.SET_NULL, null=True, blank=True, related_name="previous_matches")
    
    # Results
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.SCHEDULED)
    winner_entry = models.ForeignKey(TournamentEntry, on_delete=models.SET_NULL, null=True, blank=True, related_name="matches_won")
    
    player1_score = models.IntegerField(default=0)  # Legs/sets won
    player2_score = models.IntegerField(default=0)
    
    # Game reference
    game = models.ForeignKey("games.Game", on_delete=models.SET_NULL, null=True, blank=True)
    
    # Timing
    scheduled_time = models.DateTimeField(null=True, blank=True)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ["round__round_number", "match_number"]
    
    def __str__(self):
        p1 = self.player1_entry.player if self.player1_entry else "TBD"
        p2 = self.player2_entry.player if self.player2_entry else "TBD"
        return f"{self.tournament.name} - {p1} vs {p2}"


class TournamentInvitation(models.Model):
    """Direct invitations to players (for invite-only tournaments)"""
    
    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        ACCEPTED = "ACCEPTED", "Accepted"
        DECLINED = "DECLINED", "Declined"
        EXPIRED = "EXPIRED", "Expired"
    
    tournament = models.ForeignKey(Tournament, on_delete=models.CASCADE, related_name="invitations")
    player = models.ForeignKey("accounts.User", on_delete=models.CASCADE, related_name="tournament_invitations")
    invited_by = models.ForeignKey("accounts.User", on_delete=models.SET_NULL, null=True, related_name="sent_invitations")
    
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    message = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    responded_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField()
    
    class Meta:
        unique_together = ["tournament", "player"]
        ordering = ["-created_at"]
    
    def __str__(self):
        return f"Invitation: {self.player} to {self.tournament.name}"


class PlayerTournamentRating(models.Model):
    """Track overall player ratings across all tournaments (ELO-style system)"""
    
    player = models.OneToOneField("accounts.User", on_delete=models.CASCADE, related_name="tournament_rating")
    
    # Rating System (ELO-based)
    rating = models.IntegerField(default=1500, help_text="Current tournament rating")
    peak_rating = models.IntegerField(default=1500)
    lowest_rating = models.IntegerField(default=1500)
    
    # Tournament Stats
    tournaments_played = models.IntegerField(default=0)
    tournaments_won = models.IntegerField(default=0)
    tournaments_runner_up = models.IntegerField(default=0)
    tournaments_top_4 = models.IntegerField(default=0)
    
    # Match Stats
    total_matches_won = models.IntegerField(default=0)
    total_matches_lost = models.IntegerField(default=0)
    
    # Points
    total_tournament_points = models.IntegerField(default=0)
    
    # Skill Level
    skill_tier = models.CharField(max_length=20, default="BRONZE", choices=[
        ("BRONZE", "Bronze"),
        ("SILVER", "Silver"),
        ("GOLD", "Gold"),
        ("PLATINUM", "Platinum"),
        ("DIAMOND", "Diamond"),
        ("MASTER", "Master"),
        ("GRANDMASTER", "Grandmaster"),
    ])
    
    # Meta
    last_tournament_date = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ["-rating"]
    
    def __str__(self):
        return f"{self.player.username} - Rating: {self.rating}"
    
    @property
    def win_rate(self):
        total = self.total_matches_won + self.total_matches_lost
        if total == 0:
            return 0.0
        return (self.total_matches_won / total) * 100
    
    def update_skill_tier(self):
        """Update skill tier based on rating"""
        if self.rating >= 2400:
            self.skill_tier = "GRANDMASTER"
        elif self.rating >= 2200:
            self.skill_tier = "MASTER"
        elif self.rating >= 2000:
            self.skill_tier = "DIAMOND"
        elif self.rating >= 1800:
            self.skill_tier = "PLATINUM"
        elif self.rating >= 1600:
            self.skill_tier = "GOLD"
        elif self.rating >= 1400:
            self.skill_tier = "SILVER"
        else:
            self.skill_tier = "BRONZE"
        
        # Update peak/lowest
        if self.rating > self.peak_rating:
            self.peak_rating = self.rating
        if self.rating < self.lowest_rating:
            self.lowest_rating = self.rating
    
    def calculate_rating_change(self, opponent_rating, won, k_factor=32):
        """Calculate ELO rating change"""
        expected_score = 1 / (1 + 10 ** ((opponent_rating - self.rating) / 400))
        actual_score = 1 if won else 0
        rating_change = int(k_factor * (actual_score - expected_score))
        return rating_change


class TournamentStanding(models.Model):
    """Real-time standings/leaderboard for a tournament"""
    
    tournament = models.ForeignKey(Tournament, on_delete=models.CASCADE, related_name="standings")
    entry = models.ForeignKey(TournamentEntry, on_delete=models.CASCADE, related_name="standings")
    
    # Current Position
    rank = models.IntegerField(help_text="Current ranking in tournament")
    
    # Match Performance
    matches_played = models.IntegerField(default=0)
    matches_won = models.IntegerField(default=0)
    matches_lost = models.IntegerField(default=0)
    matches_drawn = models.IntegerField(default=0)
    
    # Scoring
    points_for = models.IntegerField(default=0, help_text="Total points scored")
    points_against = models.IntegerField(default=0, help_text="Total points conceded")
    points_difference = models.IntegerField(default=0)
    
    # Tournament Points (for ranking)
    tournament_points = models.IntegerField(default=0, help_text="Points from wins/draws")
    
    # Performance Metrics
    average_score = models.DecimalField(max_digits=6, decimal_places=2, default=0)
    highest_score = models.IntegerField(default=0)
    
    # Tiebreak Metrics (Buchholz, Sonneborn-Berger)
    buchholz_score = models.DecimalField(max_digits=6, decimal_places=2, default=0, help_text="Sum of opponents' scores (for Swiss)")
    sonneborn_berger = models.DecimalField(max_digits=6, decimal_places=2, default=0, help_text="Weighted opponent score")
    
    # Head-to-head tiebreak
    head_to_head_wins = models.IntegerField(default=0, help_text="Wins against tied opponents")
    
    # Meta
    last_updated = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ["tournament", "entry"]
        ordering = [
            "rank", 
            "-tournament_points", 
            "-points_difference",
            "-buchholz_score",
            "-sonneborn_berger",
            "-points_for"
        ]
    
    def __str__(self):
        return f"{self.tournament.name} - #{self.rank} {self.entry.player.username}"
    
    def update_statistics(self):
        """Update all statistics based on matches"""
        self.points_difference = self.points_for - self.points_against
        if self.matches_played > 0:
            self.average_score = self.points_for / self.matches_played
    
    def calculate_buchholz(self):
        """Calculate Buchholz score (sum of opponents' tournament points)"""
        from django.db.models import Sum
        
        # Get all matches for this entry
        matches = TournamentMatch.objects.filter(
            tournament=self.tournament,
            status=TournamentMatch.Status.COMPLETED
        ).filter(
            models.Q(player1_entry=self.entry) | models.Q(player2_entry=self.entry)
        )
        
        total = 0
        for match in matches:
            # Get opponent
            opponent = match.player2_entry if match.player1_entry == self.entry else match.player1_entry
            if opponent:
                opponent_standing = TournamentStanding.objects.filter(
                    tournament=self.tournament,
                    entry=opponent
                ).first()
                if opponent_standing:
                    total += opponent_standing.tournament_points
        
        self.buchholz_score = total
        return total
    
    def calculate_sonneborn_berger(self):
        """Calculate Sonneborn-Berger score (weighted by win/draw/loss)"""
        matches = TournamentMatch.objects.filter(
            tournament=self.tournament,
            status=TournamentMatch.Status.COMPLETED
        ).filter(
            models.Q(player1_entry=self.entry) | models.Q(player2_entry=self.entry)
        )
        
        total = 0.0
        for match in matches:
            opponent = match.player2_entry if match.player1_entry == self.entry else match.player1_entry
            if opponent:
                opponent_standing = TournamentStanding.objects.filter(
                    tournament=self.tournament,
                    entry=opponent
                ).first()
                
                if opponent_standing:
                    # Weight by result: 1.0 for win, 0.5 for draw, 0.0 for loss
                    if match.winner_entry == self.entry:
                        weight = 1.0
                    elif match.winner_entry is None:  # Draw
                        weight = 0.5
                    else:
                        weight = 0.0
                    
                    total += weight * opponent_standing.tournament_points
        
        self.sonneborn_berger = total
        return total
    
    @property
    def win_rate(self):
        if self.matches_played == 0:
            return 0.0
        return (self.matches_won / self.matches_played) * 100


class MatchScoreSubmission(models.Model):
    """Track score submissions by participants"""
    
    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending Verification"
        VERIFIED = "VERIFIED", "Verified"
        DISPUTED = "DISPUTED", "Disputed"
        REJECTED = "REJECTED", "Rejected"
    
    match = models.ForeignKey(TournamentMatch, on_delete=models.CASCADE, related_name="score_submissions")
    submitted_by = models.ForeignKey("accounts.User", on_delete=models.CASCADE, related_name="submitted_scores")
    
    # Scores
    player1_score = models.IntegerField()
    player2_score = models.IntegerField()
    winner = models.ForeignKey(TournamentEntry, on_delete=models.SET_NULL, null=True, related_name="won_by_submission")
    
    # Verification
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    verified_by = models.ForeignKey("accounts.User", on_delete=models.SET_NULL, null=True, blank=True, related_name="verified_scores")
    
    # Additional Data
    notes = models.TextField(blank=True)
    passcode_used = models.CharField(max_length=20)
    
    # Meta
    submitted_at = models.DateTimeField(auto_now_add=True)
    verified_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ["-submitted_at"]
    
    def __str__(self):
        return f"Score submission for {self.match} by {self.submitted_by.username}"

