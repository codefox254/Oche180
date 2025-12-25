from django.urls import path
from .views import StatsSummaryView, PersonalBestListView, AppUsageEventView, AdminMetricsView

urlpatterns = [
    path('summary/', StatsSummaryView.as_view(), name='stats-summary'),
    path('personal-bests/', PersonalBestListView.as_view(), name='personal-bests'),
    path('usage-events/', AppUsageEventView.as_view(), name='usage-events'),
    path('admin/metrics/', AdminMetricsView.as_view(), name='admin-metrics'),
]
