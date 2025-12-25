from django.urls import path
from .views import StatsSummaryView, PersonalBestListView

urlpatterns = [
    path('summary/', StatsSummaryView.as_view(), name='stats-summary'),
    path('personal-bests/', PersonalBestListView.as_view(), name='personal-bests'),
]
