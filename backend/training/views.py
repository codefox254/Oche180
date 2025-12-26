from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone

from .models import (
    TrainingSession,
    TrainingThrow,
    TrainingPersonalBest,
    TrainingProgram,
    TrainingDrill,
    TrainingChallenge,
)
from .serializers import (
    TrainingSessionSerializer,
    TrainingThrowSerializer,
    TrainingPersonalBestSerializer,
    TrainingProgramSerializer,
    TrainingDrillSerializer,
    TrainingChallengeSerializer,
)
from accounts.models import UserProfile


class TrainingSessionViewSet(viewsets.ModelViewSet):
    serializer_class = TrainingSessionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """Only return sessions for the current user"""
        return TrainingSession.objects.filter(user=self.request.user)

    def create(self, request, *args, **kwargs):
        """Create a training session with challenge lock enforcement"""
        # If user has an active challenge, block creating any other session
        active_challenge = TrainingSession.objects.filter(
            user=request.user,
            mode=TrainingSession.Mode.CHALLENGE,
            status=TrainingSession.Status.IN_PROGRESS,
            terminated=False,
        ).exists()

        if active_challenge:
            return Response(
                {"error": "An active challenge is in progress. Complete or terminate it before starting another session."},
                status=status.HTTP_409_CONFLICT,
            )

        return super().create(request, *args, **kwargs)

    def perform_create(self, serializer):
        """Auto-assign current user when creating session"""
        serializer.save(user=self.request.user)

    @action(detail=True, methods=["patch"], url_path="complete")
    def complete(self, request, pk=None):
        """Mark training session as complete and award XP"""
        session = self.get_object()
        data = request.data
        
        # Update session data
        session.final_score = data.get("final_score", session.final_score)
        success_rate = data.get("success_rate")
        if success_rate is not None:
            session.success_rate = success_rate
        
        elapsed_seconds = data.get("elapsed_seconds")
        if elapsed_seconds is not None:
            session.elapsed_seconds = elapsed_seconds
        
        session.status = TrainingSession.Status.COMPLETED
        session.completed_at = timezone.now()
        
        # Calculate XP based on success rate and duration
        xp_earned = self._calculate_xp(session)
        session.xp_earned = xp_earned
        session.save()
        
        # Update user profile with XP
        try:
            profile = UserProfile.objects.get(user=request.user)
            profile.total_xp += xp_earned
            profile.total_training_sessions += 1
            profile.save()
        except UserProfile.DoesNotExist:
            pass
        
        return Response(self.get_serializer(session).data)

    @action(detail=True, methods=["post"], url_path="terminate")
    def terminate(self, request, pk=None):
        """Terminate an active challenge session"""
        session = self.get_object()
        if session.status != TrainingSession.Status.IN_PROGRESS:
            return Response({"error": "Session is not in progress"}, status=status.HTTP_400_BAD_REQUEST)

        session.status = TrainingSession.Status.COMPLETED
        session.terminated = True
        session.completed_at = timezone.now()
        session.save()

        return Response(self.get_serializer(session).data)

    def _calculate_xp(self, session):
        """Calculate XP based on session performance"""
        base_xp = 25  # Base XP for completing a session
        
        # Bonus for high success rate
        if session.success_rate:
            if session.success_rate >= 80:
                base_xp += 30
            elif session.success_rate >= 60:
                base_xp += 20
            elif session.success_rate >= 40:
                base_xp += 10
        
        # Bonus for longer sessions
        if session.elapsed_seconds:
            minutes = session.elapsed_seconds / 60
            if minutes >= 30:
                base_xp += 15
            elif minutes >= 20:
                base_xp += 10
            elif minutes >= 10:
                base_xp += 5
        
        return base_xp


class TrainingThrowViewSet(viewsets.ModelViewSet):
    serializer_class = TrainingThrowSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Only return throws for the current user's sessions"""
        return TrainingThrow.objects.filter(session__user=self.request.user)


class TrainingPersonalBestViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = TrainingPersonalBestSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Only return personal bests for the current user"""
        return TrainingPersonalBest.objects.filter(user=self.request.user)


class TrainingProgramViewSet(viewsets.ReadOnlyModelViewSet):
    """Programs are read-only for all users"""
    queryset = TrainingProgram.objects.all()
    serializer_class = TrainingProgramSerializer
    permission_classes = [permissions.AllowAny]


class TrainingDrillViewSet(viewsets.ReadOnlyModelViewSet):
    """Drills are read-only for all users"""
    queryset = TrainingDrill.objects.all()
    serializer_class = TrainingDrillSerializer
    permission_classes = [permissions.AllowAny]


class TrainingChallengeViewSet(viewsets.ReadOnlyModelViewSet):
    """Challenges are read-only for all users"""
    queryset = TrainingChallenge.objects.all()
    serializer_class = TrainingChallengeSerializer
    permission_classes = [permissions.AllowAny]
