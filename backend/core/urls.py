from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AppSettingsViewSet

router = DefaultRouter()
router.register(r'settings', AppSettingsViewSet, basename='settings')

urlpatterns = [
    path('', include(router.urls)),
]
