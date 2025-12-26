# Backend Integration Checklist

## Overview
The frontend is production-ready and fully wired for API integration. This document lists the backend endpoints that need to be implemented or verified.

## ✅ Completed Backend Features

### Authentication Endpoints
- ✅ `POST /api/auth/login/` - User authentication with JWT
- ✅ `POST /api/auth/register/` - New user registration
- ✅ `GET /api/auth/user/` - Get current user details
- ✅ `PATCH /api/auth/user/update/` - Update user profile
- ✅ `POST /api/auth/upload-avatar/` - Upload profile photo

### User Models
- ✅ Custom User model with email and public_username
- ✅ UserProfile model with XP, level, streaks
- ✅ Admin panels for all models

---

## 🔄 Pending Backend Endpoints

### Statistics API

#### Required Endpoints:

1. **GET /api/stats/summary/**
   ```json
   Response:
   {
     "total_games": 45,
     "total_wins": 28,
     "win_percentage": 62.2,
     "overall_average": 65.4,
     "best_game_average": 89.7,
     "total_180s": 12,
     "total_140_plus": 45,
     "total_100_plus": 120,
     "stats_by_mode": {
       "501": {"games": 30, "wins": 18, "avg": 68.2},
       "cricket": {"games": 15, "wins": 10, "avg": 58.9}
     }
   }
   ```

2. **GET /api/games/recent/?limit=10**
   ```json
   Response: [
     {
       "id": 1,
       "mode": "501",
       "score": 3,
       "opponent_score": 1,
       "date": "2025-01-15T14:30:00Z",
       "average": 72.3,
       "result": "win"
     }
   ]
   ```

3. **GET /api/stats/game-mode/{mode}/**
   ```json
   Response:
   {
     "mode": "501",
     "games_played": 30,
     "wins": 18,
     "average_score": 68.2,
     "highest_checkout": 141,
     "favorite_starting_score": 501
   }
   ```

4. **GET /api/stats/achievements/**
   ```json
   Response: [
     {
       "id": 1,
       "name": "First Blood",
       "description": "Win your first game",
       "icon": "🏆",
       "unlocked_at": "2025-01-10T10:00:00Z"
     }
   ]
   ```

5. **GET /api/stats/progress/**
   ```json
   Response:
   {
     "xp_history": [
       {"date": "2025-01-10", "xp": 100},
       {"date": "2025-01-11", "xp": 250}
     ],
     "level_progression": [
       {"level": 1, "reached_at": "2025-01-01"},
       {"level": 2, "reached_at": "2025-01-08"}
     ]
   }
   ```

#### Implementation Notes:
- Query UserProfile and Game models
- Calculate win percentage: `(total_wins / total_games) * 100`
- Aggregate statistics by game mode
- Return empty arrays/objects if no data (don't error)

---

### Tournament API

#### Required Endpoints:

1. **GET /api/tournaments/**
   - Optional query param: `?status=upcoming|live|completed`
   ```json
   Response: [
     {
       "id": 1,
       "name": "Sunday Championship",
       "format": "single_elimination",
       "status": "upcoming",
       "start_date": "2025-01-20T18:00:00Z",
       "participants_count": 8,
       "max_participants": 16,
       "is_participant": false,
       "created_by": {"id": 1, "username": "admin"}
     }
   ]
   ```

2. **GET /api/tournaments/{id}/**
   ```json
   Response:
   {
     "id": 1,
     "name": "Sunday Championship",
     "description": "Weekly tournament",
     "format": "single_elimination",
     "game_mode": "501",
     "legs_per_match": 3,
     "sets_per_match": 1,
     "status": "upcoming",
     "start_date": "2025-01-20T18:00:00Z",
     "participants": [
       {"id": 1, "username": "player1", "seed": 1}
     ],
     "bracket": {...}
   }
   ```

3. **GET /api/tournaments/{id}/matches/**
   ```json
   Response: [
     {
       "id": 1,
       "round": "quarter_final",
       "match_number": 1,
       "player1": {"id": 1, "name": "Player 1"},
       "player2": {"id": 2, "name": "Player 2"},
       "score1": 2,
       "score2": 1,
       "status": "completed",
       "winner_id": 1
     }
   ]
   ```

4. **GET /api/tournaments/{id}/standings/**
   ```json
   Response: [
     {
       "rank": 1,
       "player": {"id": 1, "username": "player1"},
       "matches_played": 3,
       "wins": 3,
       "losses": 0,
       "points": 9
     }
   ]
   ```

5. **GET /api/tournaments/live-matches/**
   ```json
   Response: [
     {
       "id": 1,
       "tournament_id": 5,
       "tournament_name": "Sunday Championship",
       "player1": {"id": 1, "name": "Player 1"},
       "player2": {"id": 2, "name": "Player 2"},
       "score1": 1,
       "score2": 1,
       "current_leg": 3,
       "total_legs": 3,
       "format": "501",
       "status": "in_progress"
     }
   ]
   ```

6. **POST /api/tournaments/{id}/join/**
   ```json
   Request: {}
   Response:
   {
     "message": "Successfully joined tournament",
     "tournament_id": 1,
     "participant_id": 5
   }
   ```

7. **POST /api/tournaments/**
   ```json
   Request:
   {
     "name": "New Tournament",
     "format": "single_elimination",
     "game_mode": "501",
     "max_participants": 16,
     "start_date": "2025-01-25T18:00:00Z"
   }
   Response:
   {
     "id": 10,
     "name": "New Tournament",
     ...
   }
   ```

8. **PATCH /api/tournaments/matches/{id}/score/**
   ```json
   Request:
   {
     "score1": 2,
     "score2": 1,
     "winner_id": 1
   }
   Response:
   {
     "id": 1,
     "score1": 2,
     "score2": 1,
     "status": "completed"
   }
   ```

#### Implementation Notes:
- Use existing Tournament and TournamentParticipant models
- Create Match model if doesn't exist:
  ```python
  class Match(models.Model):
      tournament = models.ForeignKey(Tournament, on_delete=models.CASCADE)
      round = models.CharField(max_length=50)
      player1 = models.ForeignKey(User, related_name='matches_as_p1')
      player2 = models.ForeignKey(User, related_name='matches_as_p2')
      score1 = models.IntegerField(default=0)
      score2 = models.IntegerField(default=0)
      status = models.CharField(choices=[...])
      winner = models.ForeignKey(User, null=True)
  ```
- Implement bracket generation logic for different formats
- Add WebSocket support for live score updates (optional)

---

### OAuth Social Login

#### Required Endpoints:

1. **POST /api/auth/google/**
   ```json
   Request:
   {
     "id_token": "google_oauth_token_here"
   }
   Response:
   {
     "access": "jwt_access_token",
     "refresh": "jwt_refresh_token",
     "user": {...}
   }
   ```

2. **POST /api/auth/facebook/**
3. **POST /api/auth/apple/**

#### Implementation Notes:
- Use `django-allauth` or `python-social-auth`
- Verify OAuth tokens with provider APIs
- Create or retrieve user account
- Return JWT tokens for app session

---

## 🗄️ Database Schema Updates

### Recommended Models

#### Game Model
```python
class Game(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    mode = models.CharField(max_length=50)  # '501', 'cricket', etc.
    opponent_type = models.CharField(max_length=20)  # 'ai', 'human'
    opponent_name = models.CharField(max_length=100, blank=True)
    user_score = models.IntegerField()
    opponent_score = models.IntegerField()
    result = models.CharField(max_length=10)  # 'win', 'loss', 'draw'
    average_score = models.FloatField()
    highest_score = models.IntegerField()
    count_180s = models.IntegerField(default=0)
    count_140_plus = models.IntegerField(default=0)
    count_100_plus = models.IntegerField(default=0)
    checkout_score = models.IntegerField(null=True)
    duration_seconds = models.IntegerField()
    played_at = models.DateTimeField(auto_now_add=True)
```

#### Achievement Model
```python
class Achievement(models.Model):
    code = models.CharField(max_length=50, unique=True)
    name = models.CharField(max_length=100)
    description = models.TextField()
    icon = models.CharField(max_length=10)  # Emoji
    xp_reward = models.IntegerField(default=50)

class UserAchievement(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    achievement = models.ForeignKey(Achievement, on_delete=models.CASCADE)
    unlocked_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('user', 'achievement')
```

#### Match Model (if not exists)
```python
class Match(models.Model):
    STATUS_CHOICES = [
        ('scheduled', 'Scheduled'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    
    tournament = models.ForeignKey('Tournament', on_delete=models.CASCADE)
    round = models.CharField(max_length=50)
    match_number = models.IntegerField()
    player1 = models.ForeignKey(User, related_name='matches_as_p1')
    player2 = models.ForeignKey(User, related_name='matches_as_p2', null=True)
    score1 = models.IntegerField(default=0)
    score2 = models.IntegerField(default=0)
    current_leg = models.IntegerField(default=1)
    total_legs = models.IntegerField(default=3)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES)
    winner = models.ForeignKey(User, null=True, related_name='won_matches')
    started_at = models.DateTimeField(null=True)
    completed_at = models.DateTimeField(null=True)
```

---

## 📊 Admin Panel Enhancements

### Suggested Admin Actions

1. **UserAdmin:**
   - ✅ Already has UserProfile inline
   - Add: "Reset Password" action
   - Add: "Deactivate Account" action

2. **TournamentAdmin:**
   - Add: "Start Tournament" action
   - Add: "Generate Bracket" action
   - Add: "Cancel Tournament" action
   - Display: Participant count

3. **GameAdmin:**
   - Add: Filter by mode, result, date
   - Add: Search by username
   - Display: Average score, result

---

## 🔐 Security Considerations

### JWT Token Settings
```python
# backend/settings.py
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
}
```

### CORS Configuration
```python
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",  # Flutter web
    # Add production domains
]
```

### File Upload Limits
```python
# For avatar uploads
FILE_UPLOAD_MAX_MEMORY_SIZE = 5 * 1024 * 1024  # 5MB
DATA_UPLOAD_MAX_MEMORY_SIZE = 5 * 1024 * 1024
```

---

## 🧪 Backend Testing

### Test Cases to Implement

1. **Auth Tests:**
   ```python
   def test_login_with_email(self):
       # Test login with email
       
   def test_login_with_username(self):
       # Test login with username
       
   def test_token_refresh(self):
       # Test JWT refresh
   ```

2. **Statistics Tests:**
   ```python
   def test_stats_summary_empty_profile(self):
       # Should return zeros
       
   def test_stats_summary_with_games(self):
       # Should calculate correctly
   ```

3. **Tournament Tests:**
   ```python
   def test_join_tournament(self):
       # User joins tournament
       
   def test_cannot_join_full_tournament(self):
       # Should return error
       
   def test_bracket_generation_single_elim(self):
       # Verify correct bracket structure
   ```

---

## 📦 Python Packages Needed

```bash
# If not already installed
pip install djangorestframework
pip install djangorestframework-simplejwt
pip install django-cors-headers
pip install Pillow  # For image processing
pip install django-allauth  # For OAuth (optional)
```

---

## 🚀 Deployment Steps

### Database Migrations
```bash
python manage.py makemigrations
python manage.py migrate
```

### Create Achievements (One-time)
```python
# Create initial achievements
Achievement.objects.create(
    code='first_win',
    name='First Blood',
    description='Win your first game',
    icon='🏆',
    xp_reward=100
)
```

### Collect Static Files
```bash
python manage.py collectstatic
```

### Run Server
```bash
python manage.py runserver
```

---

## ✅ Verification Checklist

Before marking as complete, verify:

- [ ] All `/api/stats/*` endpoints return valid JSON
- [ ] Tournament listing works with filters
- [ ] Live matches endpoint includes in-progress games
- [ ] User can join/leave tournaments
- [ ] Match scores update correctly
- [ ] Statistics calculate win percentage accurately
- [ ] Avatar uploads save to media directory
- [ ] CORS allows frontend requests
- [ ] JWT tokens refresh properly
- [ ] Error responses include helpful messages
- [ ] All endpoints require authentication (except register/login)
- [ ] Admin panel displays new models
- [ ] Database queries are optimized (use select_related/prefetch_related)

---

## 📞 Frontend Integration Points

The frontend is calling these services:

1. **AuthService** → `backend/accounts/` endpoints
2. **StatisticsService** → `backend/user_stats/` endpoints (TO BE CREATED)
3. **TournamentApiService** → `backend/tournaments/` endpoints (PARTIAL)

Make sure URL patterns match:
```python
# backend/urls.py
urlpatterns = [
    path('api/auth/', include('accounts.urls')),
    path('api/stats/', include('user_stats.urls')),  # NEW
    path('api/tournaments/', include('tournaments.urls')),
    path('api/games/', include('games.urls')),  # NEW for recent games
]
```

---

**Status:** 🔄 In Progress
**Priority:** High - Required for full frontend functionality
**Estimated Effort:** 2-3 days for core features
**Last Updated:** 2025
