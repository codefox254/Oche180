# Training Authentication Fix

## Problem
The training system was returning 401 Unauthorized errors when users tried to start training sessions, even when logged in.

## Root Causes Identified

### Backend Issues (FIXED ✅)

1. **Custom Permission Class Bug** 
   - Location: `backend/training/views.py`
   - Issue: `IsAuthenticatedOrReadOnly` custom permission class was incorrectly allowing POST requests without authentication
   - Fix: Changed to Django's built-in `permissions.IsAuthenticated`

2. **No User Filtering**
   - Issue: `TrainingSession.objects.all()` returned ALL sessions from all users
   - Fix: Added `get_queryset()` method to filter by `request.user`

3. **No XP Calculation**
   - Issue: Training sessions didn't award XP to users
   - Fix: Implemented XP calculation in `complete()` action:
     - Base XP: 25 points
     - Success rate bonus: up to 30 points
     - Duration bonus: up to 15 points
     - Auto-updates `UserProfile.total_xp` and `UserProfile.total_training_sessions`

### Frontend Issues (FIXED ✅)

1. **Wrong Auth Header Format**
   - Location: `frontend/lib/features/training/data/training_api.dart` line 13
   - Issue: Used `'Authorization': 'Bearer $authToken'` (JWT format)
   - Fix: Changed to `'Authorization': 'Token $authToken'` (Django token format)

2. **Missing Auth Token in Training Screen**
   - Location: `frontend/lib/features/training/presentation/training_screen.dart` line 16
   - Issue: `TrainingApi` was instantiated without passing the auth token
   - Fix: 
     - Converted from `StatefulWidget` to `ConsumerStatefulWidget`
     - Added import for `authProvider`
     - Get token from `ref.watch(authProvider)`
     - Pass token to `TrainingApi` constructor

## Changes Made

### Backend (`backend/training/views.py`)

```python
# Before
class TrainingSessionViewSet(viewsets.ModelViewSet):
    queryset = TrainingSession.objects.all()  # ❌ All sessions
    permission_classes = [IsAuthenticatedOrReadOnly]  # ❌ Bug

# After
class TrainingSessionViewSet(viewsets.ModelViewSet):
    queryset = TrainingSession.objects.all()
    permission_classes = [permissions.IsAuthenticated]  # ✅ Proper auth
    
    def get_queryset(self):
        return TrainingSession.objects.filter(user=self.request.user)  # ✅ User's sessions only
    
    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        session = self.get_object()
        # ... XP calculation logic ...
        profile.total_xp += xp_earned
        profile.total_training_sessions += 1
        profile.save()
```

### Frontend (`training_api.dart`)

```dart
// Before
headers['Authorization'] = 'Bearer $authToken';  // ❌ Wrong format

// After
headers['Authorization'] = 'Token $authToken';  // ✅ Django format
```

### Frontend (`training_screen.dart`)

```dart
// Before
class TrainingScreen extends StatefulWidget {  // ❌ Can't access Riverpod
  // ...
}

class _TrainingScreenState extends State<TrainingScreen> {
  final TrainingApi _api = TrainingApi(baseUrl: '...');  // ❌ No token
  
  @override
  void initState() {
    super.initState();
    _loadContent();  // ❌ Called immediately
  }
}

// After
class TrainingScreen extends ConsumerStatefulWidget {  // ✅ Riverpod support
  // ...
}

class _TrainingScreenState extends ConsumerState<TrainingScreen> {
  TrainingApi? _api;  // ✅ Nullable
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = ref.watch(authProvider);  // ✅ Get auth state
    if (authState.token != null) {
      _api = TrainingApi(
        baseUrl: 'http://127.0.0.1:8000/api',
        authToken: authState.token,  // ✅ Pass token
      );
      if (_loading) {
        _loadContent();  // ✅ Load only when authenticated
      }
    }
  }
}
```

## How It Works Now

1. **User Login**
   - User logs in via auth system
   - Auth token stored in `authProvider`

2. **Training Screen Access**
   - `TrainingScreen` watches `authProvider` for changes
   - Gets auth token from provider
   - Creates `TrainingApi` with token

3. **API Requests**
   - All requests include `Authorization: Token <token>` header
   - Backend validates token
   - Backend filters data by authenticated user

4. **Starting Sessions**
   - User clicks "Start" on program/drill/challenge
   - Request sent with auth token
   - Backend creates `TrainingSession` linked to user

5. **Completing Sessions**
   - User completes training
   - Backend calculates XP earned
   - Updates `UserProfile` automatically

## Testing

To verify the fix works:

1. **Start Backend**
   ```bash
   cd backend
   python manage.py runserver
   ```

2. **Start Frontend**
   ```bash
   cd frontend
   flutter run
   ```

3. **Test Flow**
   - Login as a user
   - Navigate to Training tab
   - Start a training program/drill/challenge
   - Should see "Program started (Session X)" message
   - No 401 errors in console

## Expected Behavior

### When Logged In ✅
- Can view training programs, drills, challenges
- Can start training sessions
- Sessions are linked to user
- Only see own training sessions
- Earn XP when completing sessions

### When Logged Out ❌
- Can view training content (programs/drills/challenges are public)
- Cannot start sessions (gets "Please login" message)
- Cannot access session history

## Architecture

```
┌─────────────────────────────────────────────┐
│         Frontend (Flutter)                  │
├─────────────────────────────────────────────┤
│  TrainingScreen (ConsumerStatefulWidget)    │
│    ↓ watches                                │
│  authProvider (Riverpod)                    │
│    ↓ provides token                         │
│  TrainingApi (HTTP client)                  │
│    ↓ sends "Token <token>" header           │
└─────────────────────────────────────────────┘
                    ↓ HTTP
┌─────────────────────────────────────────────┐
│         Backend (Django)                    │
├─────────────────────────────────────────────┤
│  Token Authentication Middleware            │
│    ↓ validates token                        │
│  TrainingSessionViewSet                     │
│    ↓ filters by user                        │
│  TrainingSession.objects                    │
│    ↓ only user's sessions                   │
│  UserProfile                                │
│    ↓ updates XP                             │
└─────────────────────────────────────────────┘
```

## Files Modified

1. ✅ `backend/training/views.py` - Fixed permissions, added user filtering, XP calculation
2. ✅ `frontend/lib/features/training/data/training_api.dart` - Fixed auth header format
3. ✅ `frontend/lib/features/training/presentation/training_screen.dart` - Converted to ConsumerWidget, added auth token

## Additional Features

### XP Calculation Formula
```python
base_xp = 25
success_rate_bonus = int((success_rate / 100) * 30)  # 0-30 points
duration_minutes = (completed - created).seconds // 60
duration_bonus = min(duration_minutes, 15)  # cap at 15 points
total_xp = base_xp + success_rate_bonus + duration_bonus
```

### Permission Matrix

| Endpoint | Method | Permission | Description |
|----------|--------|------------|-------------|
| `/api/training/programs/` | GET | AllowAny | Public content |
| `/api/training/drills/` | GET | AllowAny | Public content |
| `/api/training/challenges/` | GET | AllowAny | Public content |
| `/api/training/sessions/` | GET | IsAuthenticated | User's sessions only |
| `/api/training/sessions/` | POST | IsAuthenticated | Create session |
| `/api/training/sessions/{id}/complete/` | POST | IsAuthenticated | Complete session + award XP |
| `/api/training/throws/` | GET/POST | IsAuthenticated | User's throws only |
| `/api/training/personal-bests/` | GET/POST | IsAuthenticated | User's PBs only |

## Notes

- Auth token format is `Token <token>` not `Bearer <token>` (Django vs JWT)
- Training content (programs/drills/challenges) is public for browsing
- Sessions/throws/personal-bests require authentication
- All user data is automatically filtered by `request.user`
- XP is awarded only when completing sessions (not starting)
