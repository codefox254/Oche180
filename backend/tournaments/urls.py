from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    TournamentViewSet,
    TournamentMatchViewSet,
    PlayerTournamentRatingViewSet,
    MatchScoreSubmissionViewSet,
)

router = DefaultRouter()
router.register(r"tournaments", TournamentViewSet, basename="tournament")
router.register(r"matches", TournamentMatchViewSet, basename="tournament-match")
router.register(r"ratings", PlayerTournamentRatingViewSet, basename="player-rating")
router.register(r"score-submissions", MatchScoreSubmissionViewSet, basename="score-submission")

urlpatterns = [
    path("", include(router.urls)),
]
