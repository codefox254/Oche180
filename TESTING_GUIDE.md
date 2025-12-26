# Oche180 Testing Guide

## Quick Start Testing

### Prerequisites
1. Backend server running at `http://127.0.0.1:8000`
2. Flutter app running (iOS simulator/Android emulator/physical device)

## Test Scenarios

### 1. Guest User Experience
**Objective:** Verify limited feature access for non-authenticated users

#### Steps:
1. Launch app (should land on home screen)
2. Verify header shows "Oche180 - Professional Darts"
3. Click on **Quick Match** action card
   - ✅ Should navigate to game modes
4. Return to home, click on **Tournaments** action card
   - ✅ Should show "Login Required" dialog
   - ✅ Lock icon visible on card
5. Click **Cancel** on dialog
6. Open drawer menu (hamburger icon)
   - ✅ Drawer header shows "Oche180" and "Professional Darts Scoring"
   - ✅ Lock icons visible on:
     - Profile
     - Tournaments
     - Training
     - Statistics
   - ✅ "Login / Signup" button visible
   - ✅ No logout button
7. Click **Statistics** from drawer
   - ✅ Should show login dialog
8. Click **Training** from drawer
   - ✅ Should show login dialog

**Expected Result:** Guest can only access Quick Match, Game Modes, and Game Rules

---

### 2. User Registration
**Objective:** Create new account and verify profile setup

#### Steps:
1. From home screen or drawer, click **Login / Signup**
2. On auth landing screen, click **Sign Up**
3. Fill in registration form:
   - Email: `test@example.com`
   - Password: `TestPassword123!`
   - Confirm Password: `TestPassword123!`
   - Username: `testplayer`
4. Click **Sign Up**
   - ✅ Should show loading indicator
   - ✅ On success, navigate to home screen
   - ✅ Header shows "Hi, testplayer"

**Expected Result:** Account created, user logged in, home screen personalized

---

### 3. Login Flow
**Objective:** Authenticate existing user

#### Steps:
1. If logged in, logout first (drawer → Logout)
2. Click **Login / Signup** → **Login**
3. Enter credentials:
   - Email/Username: `test@example.com` OR `testplayer`
   - Password: `TestPassword123!`
4. Click **Login**
   - ✅ Should authenticate successfully
   - ✅ Navigate to home screen
   - ✅ Greeting shows user's name

**Alternative: Social Login (Pending Backend)**
1. Click Google/Facebook/Apple icon
   - Currently stubbed - will show dialog

**Expected Result:** User authenticated, session persisted

---

### 4. Profile Management
**Objective:** View and edit user profile

#### Steps:
1. Ensure logged in
2. Navigate to Profile (drawer → Profile OR top-right profile icon)
3. **View Profile:**
   - ✅ Shows username
   - ✅ Shows email
   - ✅ Displays XP: X points
   - ✅ Shows Level: X
   - ✅ Shows Current Streak: X days
   - ✅ Shows Total Games Played: X
4. Click **Edit Profile** button
5. **Test Photo Upload:**
   - Click camera icon
   - Select "Choose from gallery"
   - Pick an image
   - ✅ Photo preview updates
6. **Test Avatar Selection:**
   - Click **Choose Avatar** button
   - Select emoji (e.g., 🎯)
   - ✅ Avatar displayed instead of photo
7. **Edit Text Fields:**
   - Update username to `testplayer2`
   - Change first name to `Test`
   - Change last name to `Player`
8. Click **Save Changes**
   - ✅ Shows success message
   - ✅ Returns to profile screen
   - ✅ Changes reflected

**Expected Result:** Profile updated successfully, changes persist

---

### 5. Personalized Home Screen
**Objective:** Verify dynamic content based on auth state

#### Steps:
1. Login as user with game history
2. **Check Header:**
   - ✅ "Hi, {firstName}" greeting
   - ✅ "Ready to play?" subtitle
3. **Check Stats Overview:**
   - ✅ Shows real XP count
   - ✅ Shows actual level
   - ✅ Shows total games played
4. **Check Quick Actions:**
   - ✅ No lock icons visible (all accessible)
   - ✅ Click Tournaments → navigates without dialog
   - ✅ Click Statistics → navigates without dialog

**Expected Result:** All user data dynamically displayed

---

### 6. Statistics Screen
**Objective:** View user statistics and recent games

#### Steps:
1. Ensure logged in
2. Navigate to Statistics (home → Statistics card OR drawer → Statistics)
3. **Verify Data Display:**
   - ✅ Overview section shows:
     - Total games played
     - Total wins
     - Win percentage
   - ✅ Averages section shows:
     - Overall average
     - Best game average
   - ✅ Highlights section shows:
     - Total 180s
     - Total 140+ scores
     - Total 100+ scores
4. Pull down to refresh
   - ✅ Spinner appears
   - ✅ Data reloads
5. **Test Error State (if backend down):**
   - Stop backend server
   - Refresh statistics
   - ✅ Error icon and message displayed
   - ✅ "Retry" button appears

**Expected Result:** Statistics displayed accurately, refresh works

---

### 7. Tournament Screen (Livescore Style)
**Objective:** View live matches and tournament listings

#### Steps:
1. Ensure logged in
2. Navigate to Tournaments (home → Tournaments card)
3. **Live Matches Tab:**
   - ✅ Shows list of ongoing matches
   - ✅ Each match card displays:
     - Pulsing red "LIVE" badge
     - Player names with avatars
     - Current scores
     - Leading player highlighted
     - Leg progress (e.g., "Leg 2/3")
     - Tournament name
     - Game format
   - ✅ Tap match → navigates to match details
4. **Upcoming Tournaments Tab:**
   - ✅ Shows upcoming tournament cards
   - ✅ Each card displays:
     - Tournament name
     - Format (e.g., "Single Elimination")
     - Participant count (e.g., "8/16")
     - Start date
     - Status badge (UPCOMING)
   - ✅ Tap tournament → navigates to details
5. **My Tournaments Tab:**
   - ✅ Shows only tournaments user joined
   - ✅ Empty state if no tournaments joined
6. **Create Tournament:**
   - ✅ FAB button visible (bottom-right)
   - Tap to create (form pending implementation)

**Expected Result:** Livescore-style UI with real-time feel

---

### 8. Feature Gating
**Objective:** Verify auth guards work correctly

#### Test Matrix:

| Feature | Guest Access | Logged In Access |
|---------|-------------|------------------|
| Quick Match | ✅ Yes | ✅ Yes |
| Game Modes | ✅ Yes | ✅ Yes |
| Game Rules | ✅ Yes | ✅ Yes |
| Tournaments | ❌ No (Login Dialog) | ✅ Yes |
| Statistics | ❌ No (Login Dialog) | ✅ Yes |
| Training | ❌ No (Login Dialog) | ✅ Yes |
| Profile | ❌ No (Login Dialog) | ✅ Yes |

**Steps:**
1. Logout completely
2. Try accessing each feature
3. Verify lock icons appear for restricted features
4. Verify login dialogs trigger correctly
5. Login
6. Verify all features accessible
7. Verify lock icons disappear

**Expected Result:** Feature access correctly gated

---

### 9. Session Persistence
**Objective:** Verify login session persists across app restarts

#### Steps:
1. Login to app
2. Navigate around (profile, stats, etc.)
3. **Close app completely** (swipe away from multitasking)
4. Relaunch app
   - ✅ Should open to home screen (not auth)
   - ✅ User still logged in
   - ✅ Greeting shows username
   - ✅ Profile data accessible
5. **Test Logout:**
   - Drawer → Logout
   - ✅ Navigate to auth screen
   - ✅ Close and reopen app
   - ✅ Should remain logged out

**Expected Result:** Token persisted in SharedPreferences

---

### 10. Logout Flow
**Objective:** Verify clean logout and state reset

#### Steps:
1. Login to app
2. Navigate to several screens (profile, stats, tournaments)
3. Open drawer → click **Logout**
   - ✅ Navigate to auth landing screen
   - ✅ Home screen (if navigated to) shows guest state:
     - "Oche180" header (not personalized)
     - Default/sample stats
     - Lock icons on restricted features
4. Try accessing profile from drawer
   - ✅ Login dialog appears
5. Check app state:
   - ✅ No user data cached
   - ✅ Token cleared from storage

**Expected Result:** Complete session cleanup

---

## Edge Cases to Test

### Network Errors
1. Disable WiFi/mobile data
2. Try to login
   - ✅ Shows connection error
3. Navigate to statistics
   - ✅ Shows error state with retry button
4. Enable network
5. Click Retry
   - ✅ Data loads successfully

### Invalid Credentials
1. Login with wrong password
   - ✅ Shows "Invalid credentials" error
   - ✅ Form remains filled
2. Login with non-existent email
   - ✅ Shows appropriate error message

### Form Validation
1. Signup with mismatched passwords
   - ✅ Shows validation error
2. Signup with short username (<6 chars)
   - ✅ Shows "Username must be at least 6 characters"
3. Signup with invalid email format
   - ✅ Shows "Invalid email" error

### Image Upload
1. Edit profile → upload very large image (>10MB)
   - ⚠️ May be slow, compression recommended
2. Upload invalid file type
   - ✅ Should reject or show error

---

## Performance Testing

### Loading States
- ✅ Login shows spinner while authenticating
- ✅ Statistics shows loading indicator while fetching
- ✅ Tournaments shows loading during data fetch
- ✅ Profile edit shows feedback during save

### Smooth Transitions
- ✅ Navigation animations fluid
- ✅ No janky scrolling
- ✅ Images load without layout shift

---

## Accessibility Testing

### Screen Reader
1. Enable TalkBack (Android) or VoiceOver (iOS)
2. Navigate through app
   - ✅ All buttons announced
   - ✅ Form fields labeled
   - ✅ Error messages read aloud

### Touch Targets
- ✅ All buttons at least 48x48dp
- ✅ Lock icons don't interfere with card taps

---

## Device Testing Matrix

| Device Type | OS | Screen Size | Status |
|-------------|-----|------------|--------|
| iPhone 15 Pro | iOS 17 | 6.1" | ⏳ Pending |
| Pixel 8 | Android 14 | 6.2" | ⏳ Pending |
| iPad Pro | iOS 17 | 12.9" | ⏳ Pending |
| Samsung Tab | Android 13 | 10.1" | ⏳ Pending |

---

## Automation Test Ideas

### Unit Tests
```dart
test('AuthProvider login success', () async {
  // Mock API response
  // Call login
  // Verify state updated
});

test('canAccessFeature returns false for guest', () {
  // Test feature gating logic
});
```

### Widget Tests
```dart
testWidgets('Login screen validates email', (tester) async {
  // Render LoginScreen
  // Enter invalid email
  // Tap submit
  // Expect error message
});
```

### Integration Tests
```dart
testWidgets('End-to-end login flow', (tester) async {
  // Open app
  // Navigate to login
  // Fill credentials
  // Submit form
  // Verify home screen shows user data
});
```

---

## Bug Reporting Template

**Title:** [Component] Brief description

**Steps to Reproduce:**
1. Step one
2. Step two
3. Step three

**Expected Result:**
What should happen

**Actual Result:**
What actually happened

**Screenshots/Logs:**
Attach if available

**Environment:**
- Device: iPhone 15 Pro
- OS: iOS 17.2
- App Version: 1.0.0
- Backend Version: Django 4.x

---

## Test Results Log

### Date: _________
### Tester: _________

| Test Scenario | Status | Notes |
|--------------|--------|-------|
| 1. Guest Experience | ⏳ | |
| 2. Registration | ⏳ | |
| 3. Login | ⏳ | |
| 4. Profile Management | ⏳ | |
| 5. Home Screen | ⏳ | |
| 6. Statistics | ⏳ | |
| 7. Tournaments | ⏳ | |
| 8. Feature Gating | ⏳ | |
| 9. Session Persistence | ⏳ | |
| 10. Logout | ⏳ | |

**Overall Pass Rate:** ____ / 10

**Critical Issues Found:**
- 

**Minor Issues Found:**
- 

**Recommendations:**
- 

---

**Last Updated:** 2025
**Version Tested:** 1.0.0
