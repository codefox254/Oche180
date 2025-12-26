from django.urls import path
from . import views

urlpatterns = [
    path("login/", views.login_view, name="login"),
    path("signup/", views.signup_view, name="signup"),
    path("logout/", views.logout_view, name="logout"),
    path("user/", views.get_current_user, name="current-user"),
    path("user/update/", views.update_user_profile, name="update-profile"),
]
