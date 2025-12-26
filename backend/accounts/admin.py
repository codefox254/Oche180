from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from .models import User, UserProfile


class UserProfileInline(admin.StackedInline):
    model = UserProfile
    can_delete = False
    verbose_name_plural = "Profile"
    fk_name = "user"
    extra = 0  # Do not render blank inline on add; profile is created via signal
    max_num = 1


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    model = User
    list_display = (
        "id",
        "email",
        "public_username",
        "first_name",
        "last_name",
        "skill_level",
        "is_active",
        "is_staff",
    )
    ordering = ("email",)
    search_fields = ("email", "first_name", "last_name")

    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Personal info", {"fields": ("public_username", "first_name", "last_name", "avatar", "skill_level")}),
        (
            "Permissions",
            {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")},
        ),
        ("Important dates", {"fields": ("last_login", "date_joined")}),
    )

    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("email", "public_username", "password1", "password2", "skill_level"),
            },
        ),
    )

    filter_horizontal = (
        "groups",
        "user_permissions",
    )

    inlines = [UserProfileInline]


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "total_xp",
        "level",
        "current_streak",
        "longest_streak",
        "total_training_sessions",
        "total_games_played",
    )
    search_fields = ("user__email",)
    list_filter = ("level",)
