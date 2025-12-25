from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    TrainingSessionViewSet,
    TrainingThrowViewSet,
    TrainingPersonalBestViewSet,
    TrainingProgramViewSet,
    TrainingDrillViewSet,
    TrainingChallengeViewSet,
)

router = DefaultRouter()
router.register(r"sessions", TrainingSessionViewSet, basename="training-session")
router.register(r"throws", TrainingThrowViewSet, basename="training-throw")
router.register(r"personal-bests", TrainingPersonalBestViewSet, basename="training-pb")
router.register(r"programs", TrainingProgramViewSet, basename="training-program")
router.register(r"drills", TrainingDrillViewSet, basename="training-drill")
router.register(r"challenges", TrainingChallengeViewSet, basename="training-challenge")

urlpatterns = [
    path("", include(router.urls)),
]
