from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

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


class IsAuthenticatedOrReadOnly(permissions.BasePermission):
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return request.user and request.user.is_authenticated


class TrainingSessionViewSet(viewsets.ModelViewSet):
    queryset = TrainingSession.objects.all()
    serializer_class = TrainingSessionSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=["patch"], url_path="complete")
    def complete(self, request, pk=None):
        session = self.get_object()
        data = request.data
        session.final_score = data.get("final_score", session.final_score)
        success_rate = data.get("success_rate")
        if success_rate is not None:
            session.success_rate = success_rate
        session.status = TrainingSession.Status.COMPLETED
        session.save()
        return Response(self.get_serializer(session).data)


class TrainingThrowViewSet(viewsets.ModelViewSet):
    queryset = TrainingThrow.objects.all()
    serializer_class = TrainingThrowSerializer
    permission_classes = [permissions.IsAuthenticated]


class TrainingPersonalBestViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = TrainingPersonalBest.objects.all()
    serializer_class = TrainingPersonalBestSerializer
    permission_classes = [permissions.IsAuthenticated]


class TrainingProgramViewSet(viewsets.ModelViewSet):
    queryset = TrainingProgram.objects.all()
    serializer_class = TrainingProgramSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]


class TrainingDrillViewSet(viewsets.ModelViewSet):
    queryset = TrainingDrill.objects.all()
    serializer_class = TrainingDrillSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]


class TrainingChallengeViewSet(viewsets.ModelViewSet):
    queryset = TrainingChallenge.objects.all()
    serializer_class = TrainingChallengeSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
