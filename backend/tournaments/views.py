from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from django.db import transaction
from django.shortcuts import get_object_or_404

from .models import Tournament, TournamentEntry, TournamentMatch, TournamentInvitation, PlayerTournamentRating, TournamentStanding, MatchScoreSubmission
from .serializers import (
    TournamentListSerializer,
    TournamentDetailSerializer,
    TournamentCreateSerializer,
    TournamentEntrySerializer,
    TournamentMatchSerializer,
    TournamentInvitationSerializer,
    BatchEntrySerializer,
    PlayerTournamentRatingSerializer,
    TournamentStandingSerializer,
    MatchScoreSubmissionSerializer,
    ScoreSubmissionCreateSerializer,
)
from .bracket_generator import BracketGenerator


class IsOrganizerOrReadOnly(permissions.BasePermission):
    """Allow organizer to edit, others to read"""
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.organizer == request.user or request.user.is_staff


class TournamentViewSet(viewsets.ModelViewSet):
    """ViewSet for tournaments"""
    queryset = Tournament.objects.all()
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    
    def get_serializer_class(self):
        if self.action == "list":
            return TournamentListSerializer
        elif self.action == "create":
            return TournamentCreateSerializer
        return TournamentDetailSerializer
    
    def get_permissions(self):
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]
    
    def perform_create(self, serializer):
        """Create tournament with current user as organizer"""
        serializer.save(organizer=self.request.user)
    
    @action(detail=True, methods=["post"])
    def register(self, request, pk=None):
        """Register current user for tournament"""
        tournament = self.get_object()
        
        # Check if registration is open
        if not tournament.is_registration_open:
            return Response(
                {"error": "Registration is not open"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check password if required
        if tournament.registration_password:
            password = request.data.get("password", "")
            if password != tournament.registration_password:
                return Response(
                    {"error": "Invalid registration password"},
                    status=status.HTTP_403_FORBIDDEN
                )
        
        # Check skill level requirement
        if tournament.min_skill_level:
            user_skill = request.user.skill_level
            skill_order = ["BEGINNER", "INTERMEDIATE", "ADVANCED", "PROFESSIONAL"]
            if skill_order.index(user_skill) < skill_order.index(tournament.min_skill_level):
                return Response(
                    {"error": f"Minimum skill level required: {tournament.min_skill_level}"},
                    status=status.HTTP_403_FORBIDDEN
                )
        
        # Create entry
        entry_status = TournamentEntry.Status.PENDING if tournament.require_approval else TournamentEntry.Status.CONFIRMED
        
        entry, created = TournamentEntry.objects.get_or_create(
            tournament=tournament,
            player=request.user,
            defaults={"status": entry_status}
        )
        
        if not created:
            return Response(
                {"error": "Already registered for this tournament"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if entry.status == TournamentEntry.Status.CONFIRMED:
            entry.approved_at = timezone.now()
            entry.save()
        
        serializer = TournamentEntrySerializer(entry)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=["post"])
    def withdraw(self, request, pk=None):
        """Withdraw from tournament"""
        tournament = self.get_object()
        
        try:
            entry = TournamentEntry.objects.get(tournament=tournament, player=request.user)
        except TournamentEntry.DoesNotExist:
            return Response(
                {"error": "Not registered for this tournament"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if tournament.status == Tournament.Status.IN_PROGRESS:
            return Response(
                {"error": "Cannot withdraw after tournament has started"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        entry.status = TournamentEntry.Status.WITHDRAWN
        entry.save()
        
        return Response({"message": "Withdrawn successfully"})
    
    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def add_players(self, request, pk=None):
        """Batch add players to tournament (organizers only)"""
        tournament = self.get_object()
        
        if tournament.organizer != request.user and not request.user.is_staff:
            return Response(
                {"error": "Only tournament organizer can add players"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer = BatchEntrySerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        player_ids = serializer.validated_data["player_ids"]
        auto_approve = serializer.validated_data["auto_approve"]
        
        added = []
        errors = []
        
        with transaction.atomic():
            for player_id in player_ids:
                try:
                    from accounts.models import User
                    player = User.objects.get(id=player_id)
                    
                    entry_status = TournamentEntry.Status.CONFIRMED if auto_approve else TournamentEntry.Status.PENDING
                    
                    entry, created = TournamentEntry.objects.get_or_create(
                        tournament=tournament,
                        player=player,
                        defaults={"status": entry_status}
                    )
                    
                    if created:
                        if entry_status == TournamentEntry.Status.CONFIRMED:
                            entry.approved_at = timezone.now()
                            entry.save()
                        added.append(player.email)
                    else:
                        errors.append(f"{player.email} already registered")
                
                except User.DoesNotExist:
                    errors.append(f"Player ID {player_id} not found")
        
        return Response({
            "added": added,
            "errors": errors,
            "total_added": len(added)
        })
    
    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def approve_entry(self, request, pk=None):
        """Approve pending entry (organizers only)"""
        tournament = self.get_object()
        
        if tournament.organizer != request.user and not request.user.is_staff:
            return Response(
                {"error": "Only tournament organizer can approve entries"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        entry_id = request.data.get("entry_id")
        try:
            entry = TournamentEntry.objects.get(id=entry_id, tournament=tournament)
        except TournamentEntry.DoesNotExist:
            return Response(
                {"error": "Entry not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        
        if entry.status != TournamentEntry.Status.PENDING:
            return Response(
                {"error": "Entry is not pending"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        entry.status = TournamentEntry.Status.CONFIRMED
        entry.approved_at = timezone.now()
        entry.save()
        
        return Response(TournamentEntrySerializer(entry).data)
    
    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def start_tournament(self, request, pk=None):
        """Start tournament and generate brackets (organizers only)"""
        tournament = self.get_object()
        
        if tournament.organizer != request.user and not request.user.is_staff:
            return Response(
                {"error": "Only tournament organizer can start tournament"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        if tournament.status != Tournament.Status.REGISTRATION_CLOSED:
            return Response(
                {"error": "Tournament must be in REGISTRATION_CLOSED status"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        confirmed_entries = tournament.entries.filter(status=TournamentEntry.Status.CONFIRMED).count()
        if confirmed_entries < tournament.min_participants:
            return Response(
                {"error": f"Not enough participants (min: {tournament.min_participants}, current: {confirmed_entries})"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Generate bracket based on format
        success = False
        if tournament.tournament_format == Tournament.Format.SINGLE_ELIMINATION:
            success = BracketGenerator.generate_single_elimination(tournament)
        elif tournament.tournament_format == Tournament.Format.DOUBLE_ELIMINATION:
            success = BracketGenerator.generate_double_elimination(tournament)
        elif tournament.tournament_format == Tournament.Format.ROUND_ROBIN:
            success = BracketGenerator.generate_round_robin(tournament)
        else:
            return Response(
                {"error": f"Bracket generation not yet implemented for {tournament.get_tournament_format_display()}"},
                status=status.HTTP_501_NOT_IMPLEMENTED
            )
        
        if success:
            tournament.status = Tournament.Status.IN_PROGRESS
            tournament.current_round = 1
            tournament.save()
            
            return Response({
                "message": "Tournament started successfully",
                "bracket_generated": True
            })
        
        return Response(
            {"error": "Failed to generate bracket"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
    @action(detail=False, methods=["get"])
    def featured(self, request):
        """Get featured tournaments"""
        tournaments = Tournament.objects.filter(is_featured=True, status__in=[
            Tournament.Status.REGISTRATION_OPEN,
            Tournament.Status.REGISTRATION_CLOSED,
            Tournament.Status.IN_PROGRESS
        ])[:10]
        
        serializer = TournamentListSerializer(tournaments, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=["get"])
    def upcoming(self, request):
        """Get upcoming tournaments"""
        now = timezone.now()
        tournaments = Tournament.objects.filter(
            start_time__gt=now,
            status__in=[Tournament.Status.REGISTRATION_OPEN, Tournament.Status.REGISTRATION_CLOSED]
        ).order_by("start_time")[:20]
        
        serializer = TournamentListSerializer(tournaments, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=["get"])
    def my_tournaments(self, request):
        """Get user's registered tournaments"""
        if not request.user.is_authenticated:
            return Response([])
        
        entries = TournamentEntry.objects.filter(player=request.user).select_related("tournament")
        tournament_ids = entries.values_list("tournament_id", flat=True)
        tournaments = Tournament.objects.filter(id__in=tournament_ids)
        
        serializer = TournamentListSerializer(tournaments, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=["post"])
    def generate_passcode(self, request, pk=None):
        """Generate a new passcode for the tournament"""
        tournament = self.get_object()
        
        # Only organizer can generate passcode
        if tournament.organizer != request.user:
            return Response(
                {"error": "Only tournament organizer can generate passcode"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        passcode = tournament.generate_passcode()
        tournament.save()
        
        return Response({
            "passcode": passcode,
            "message": "Passcode generated successfully"
        })
    
    @action(detail=True, methods=["post"])
    def verify_passcode(self, request, pk=None):
        """Verify tournament passcode"""
        tournament = self.get_object()
        passcode = request.data.get("passcode", "")
        
        is_valid = tournament.verify_passcode(passcode)
        
        return Response({
            "valid": is_valid,
            "can_submit_scores": is_valid and tournament.allow_score_submission
        })
    
    @action(detail=True, methods=["get"])
    def standings(self, request, pk=None):
        """Get tournament standings/leaderboard"""
        tournament = self.get_object()
        standings = TournamentStanding.objects.filter(tournament=tournament).select_related("entry__player")
        
        serializer = TournamentStandingSerializer(standings, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def submit_score(self, request, pk=None):
        """Submit match score with passcode"""
        tournament = self.get_object()
        
        serializer = ScoreSubmissionCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        # Verify passcode
        passcode = serializer.validated_data["passcode"]
        if not tournament.verify_passcode(passcode):
            return Response(
                {"error": "Invalid passcode"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Check if score submission is allowed
        if not tournament.allow_score_submission:
            return Response(
                {"error": "Score submission is disabled for this tournament"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Get the match
        try:
            match = TournamentMatch.objects.get(
                id=serializer.validated_data["match_id"],
                tournament=tournament
            )
        except TournamentMatch.DoesNotExist:
            return Response(
                {"error": "Match not found"},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Check if user is a participant in the match
        is_participant = (
            match.player1_entry and match.player1_entry.player == request.user or
            match.player2_entry and match.player2_entry.player == request.user
        )
        
        if not is_participant and tournament.organizer != request.user:
            return Response(
                {"error": "You must be a participant or organizer to submit scores"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Determine winner
        player1_score = serializer.validated_data["player1_score"]
        player2_score = serializer.validated_data["player2_score"]
        
        if player1_score > player2_score:
            winner = match.player1_entry
        elif player2_score > player1_score:
            winner = match.player2_entry
        else:
            return Response(
                {"error": "Scores cannot be tied"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create score submission
        submission = MatchScoreSubmission.objects.create(
            match=match,
            submitted_by=request.user,
            player1_score=player1_score,
            player2_score=player2_score,
            winner=winner,
            passcode_used=passcode,
            notes=serializer.validated_data.get("notes", ""),
            status=MatchScoreSubmission.Status.VERIFIED if request.user == tournament.organizer else MatchScoreSubmission.Status.PENDING
        )
        
        # If organizer, auto-apply the scores
        if request.user == tournament.organizer:
            match.player1_score = player1_score
            match.player2_score = player2_score
            BracketGenerator.advance_winner(match, winner)
            submission.verified_by = request.user
            submission.verified_at = timezone.now()
            submission.save()
            
            # Update standings
            self._update_standings(tournament, match, winner)
        
        return Response({
            "message": "Score submitted successfully",
            "submission_id": submission.id,
            "status": submission.status,
            "requires_verification": submission.status == MatchScoreSubmission.Status.PENDING
        })
    
    def _update_standings(self, tournament, match, winner):
        """Update tournament standings after match completion"""
        from django.db.models import F
        
        # Update or create standings for both players
        if match.player1_entry:
            standing, _ = TournamentStanding.objects.get_or_create(
                tournament=tournament,
                entry=match.player1_entry
            )
            standing.matches_played = F("matches_played") + 1
            standing.points_for = F("points_for") + (match.player1_score or 0)
            standing.points_against = F("points_against") + (match.player2_score or 0)
            
            if winner == match.player1_entry:
                standing.matches_won = F("matches_won") + 1
                standing.tournament_points = F("tournament_points") + 3  # 3 points for win
            else:
                standing.matches_lost = F("matches_lost") + 1
            
            standing.save()
            standing.refresh_from_db()
            standing.update_statistics()
            standing.save()
        
        if match.player2_entry:
            standing, _ = TournamentStanding.objects.get_or_create(
                tournament=tournament,
                entry=match.player2_entry
            )
            standing.matches_played = F("matches_played") + 1
            standing.points_for = F("points_for") + (match.player2_score or 0)
            standing.points_against = F("points_against") + (match.player1_score or 0)
            
            if winner == match.player2_entry:
                standing.matches_won = F("matches_won") + 1
                standing.tournament_points = F("tournament_points") + 3
            else:
                standing.matches_lost = F("matches_lost") + 1
            
            standing.save()
            standing.refresh_from_db()
            standing.update_statistics()
            standing.save()
        
        # Update rankings
        standings = TournamentStanding.objects.filter(tournament=tournament).order_by(
            "-tournament_points", "-points_difference", "-points_for"
        )
        
        for rank, standing in enumerate(standings, start=1):
            standing.rank = rank
            standing.save()


class TournamentMatchViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for tournament matches"""
    queryset = TournamentMatch.objects.all()
    serializer_class = TournamentMatchSerializer
    permission_classes = [permissions.AllowAny]
    
    @action(detail=True, methods=["post"], permission_classes=[permissions.IsAuthenticated])
    def report_result(self, request, pk=None):
        """Report match result"""
        match = self.get_object()
        
        # Verify user is participant or organizer
        if request.user not in [match.player1_entry.player, match.player2_entry.player, match.tournament.organizer]:
            return Response(
                {"error": "Not authorized to report result"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        winner_entry_id = request.data.get("winner_entry_id")
        player1_score = request.data.get("player1_score")
        player2_score = request.data.get("player2_score")
        
        try:
            winner_entry = TournamentEntry.objects.get(id=winner_entry_id)
        except TournamentEntry.DoesNotExist:
            return Response(
                {"error": "Invalid winner entry"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        match.player1_score = player1_score
        match.player2_score = player2_score
        
        BracketGenerator.advance_winner(match, winner_entry)
        
        return Response(TournamentMatchSerializer(match).data)


class PlayerTournamentRatingViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for player tournament ratings/leaderboard"""
    queryset = PlayerTournamentRating.objects.all()
    serializer_class = PlayerTournamentRatingSerializer
    permission_classes = [permissions.AllowAny]
    
    @action(detail=False, methods=["get"])
    def leaderboard(self, request):
        """Get global tournament leaderboard"""
        limit = int(request.query_params.get("limit", 100))
        ratings = PlayerTournamentRating.objects.all()[:limit]
        
        serializer = self.get_serializer(ratings, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=["get"], permission_classes=[permissions.IsAuthenticated])
    def my_rating(self, request):
        """Get current user's rating"""
        rating, created = PlayerTournamentRating.objects.get_or_create(player=request.user)
        
        serializer = self.get_serializer(rating)
        return Response(serializer.data)


class MatchScoreSubmissionViewSet(viewsets.ModelViewSet):
    """ViewSet for managing score submissions"""
    queryset = MatchScoreSubmission.objects.all()
    serializer_class = MatchScoreSubmissionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Filter submissions based on user role"""
        user = self.request.user
        
        # Organizers see all submissions for their tournaments
        organized_tournaments = Tournament.objects.filter(organizer=user)
        organizer_submissions = MatchScoreSubmission.objects.filter(
            match__tournament__in=organized_tournaments
        )
        
        # Users see their own submissions
        own_submissions = MatchScoreSubmission.objects.filter(submitted_by=user)
        
        # Combine both querysets
        return (organizer_submissions | own_submissions).distinct()
    
    @action(detail=True, methods=["post"])
    def verify(self, request, pk=None):
        """Verify a score submission (organizer only)"""
        submission = self.get_object()
        match = submission.match
        tournament = match.tournament
        
        # Check if user is organizer
        if tournament.organizer != request.user:
            return Response(
                {"error": "Only tournament organizer can verify scores"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Apply the scores
        match.player1_score = submission.player1_score
        match.player2_score = submission.player2_score
        
        BracketGenerator.advance_winner(match, submission.winner)
        
        # Update submission status
        submission.status = MatchScoreSubmission.Status.VERIFIED
        submission.verified_by = request.user
        submission.verified_at = timezone.now()
        submission.save()
        
        return Response({
            "message": "Score verified and applied",
            "submission": MatchScoreSubmissionSerializer(submission).data
        })
    
    @action(detail=True, methods=["post"])
    def dispute(self, request, pk=None):
        """Dispute a score submission"""
        submission = self.get_object()
        match = submission.match
        
        # Check if user is a participant in the match
        is_participant = (
            match.player1_entry and match.player1_entry.player == request.user or
            match.player2_entry and match.player2_entry.player == request.user
        )
        
        if not is_participant:
            return Response(
                {"error": "Only match participants can dispute scores"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        submission.status = MatchScoreSubmission.Status.DISPUTED
        submission.notes += f"\n\nDisputed by {request.user.email}: {request.data.get('reason', 'No reason provided')}"
        submission.save()
        
        return Response({
            "message": "Score submission disputed",
            "submission": MatchScoreSubmissionSerializer(submission).data
        })

