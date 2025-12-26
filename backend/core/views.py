from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import AppSettings
from .serializers import AppSettingsSerializer


class AppSettingsViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for app settings - read-only for clients"""
    queryset = AppSettings.objects.all()
    serializer_class = AppSettingsSerializer
    permission_classes = [permissions.AllowAny]
    
    @action(detail=False, methods=['get'])
    def current(self, request):
        """Get current app settings"""
        settings = AppSettings.get_settings()
        serializer = self.get_serializer(settings)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def features(self, request):
        """Get feature flags only"""
        settings = AppSettings.get_settings()
        return Response({
            'tournaments': settings.tournaments_enabled,
            'training': settings.training_enabled,
            'multiplayer': settings.multiplayer_enabled,
            'friendRequests': settings.friend_requests_enabled,
            'leaderboards': settings.leaderboards_enabled,
            'achievements': settings.achievements_enabled,
            'chat': settings.chat_enabled,
        })
    
    @action(detail=False, methods=['get'])
    def status(self, request):
        """Get app status (maintenance mode, etc)"""
        settings = AppSettings.get_settings()
        return Response({
            'maintenanceMode': settings.maintenance_mode,
            'maintenanceMessage': settings.maintenance_message if settings.maintenance_mode else None,
            'allowNewRegistrations': settings.allow_new_registrations,
        })
