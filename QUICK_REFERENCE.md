# Quick Reference - Game Setup Features

## What Was Added

### ✅ Player Management
- Support for **1-6 individual players** in Singles mode
- Support for **2-4 teams** with 2 players each in Team mode
- **Custom player names** for all configurations
- Dynamic name input fields that auto-generate defaults

### ✅ Game Mode Toggle
- Easy switch between "Singles" and "Teams (2v2)" modes
- Icon indicators (👤 person icon for Singles, 👥 group icon for Teams)
- Preserves team structure when switching

### ✅ User Interface
- Color-coded teams (4 different colors for up to 4 teams)
- Responsive number selectors (buttons for valid options)
- Glassmorphism design cards with borders
- Professional dark theme integration

### ✅ Data Passing
- Player names and game mode passed to GameScoringScreen
- GameScoringScreen dynamically initializes based on received data
- Supports both old (default) and new (custom) player configurations

---

## Quick Start - Using the Feature

### To Use Singles Mode (1-6 Players):
1. On Game Setup screen, tap **[Singles]** button
2. Select number of players: **[1] [2] [3] [4] [5] [6]**
3. Enter custom names or keep defaults (Player 1, Player 2, etc.)
4. Tap **[Start Game]**

### To Use Team Mode (2-4 Teams):
1. On Game Setup screen, tap **[Teams (2v2)]** button
2. Select number of teams: **[2] [3] [4]**
3. Enter player names (organized by team with color headers)
4. Tap **[Start Game]**

---

## Files Modified

| File | Changes |
|------|---------|
| `game_setup_screen.dart` | Added mode toggle, team support, dynamic player count (1-6) |
| `game_scoring_screen.dart` | Updated constructor to accept custom players |

## Files Created

| File | Purpose |
|------|---------|
| `SETUP_CHANGES.md` | Technical summary of changes |
| `GAME_SETUP_GUIDE.md` | User-facing feature guide |
| `IMPLEMENTATION_DETAILS.md` | Code implementation details |

---

## Key State Variables

```dart
bool _isTeamMode = false;           // Toggle: true=teams, false=singles
int _playerCount = 1;               // 1-6 for singles
int _teamCount = 2;                 // 2-4 for teams
List<TextEditingController> _playerControllers;  // Dynamic name inputs
```

## Key Methods

```dart
_updatePlayerCount(int count)       // Handle singles count selection
_updateTeamCount(int count)         // Handle teams count selection
_toggleTeamMode()                   // Switch between modes
```

---

## Team Colors Reference

```
Team 1: 🟢 Primary Green   (#1B5E20)
Team 2: 🟡 Accent Gold     (#FFC107)
Team 3: 🔵 Secondary Teal  (#00BCD4)
Team 4: 🔴 Error Red       (#F44336)
```

---

## UI Layouts

### Singles Mode (Example: 3 Players)
```
┌─────────────────────────────┐
│ Game Mode                   │
│ [Singles ✓] [Teams]         │
├─────────────────────────────┤
│ Number of Players (1-6)     │
│ [1] [2] [3✓] [4] [5] [6]    │
├─────────────────────────────┤
│ Player Names                │
│ [👤 Alice       ___________]│
│ [👤 Bob         ___________]│
│ [👤 Charlie     ___________]│
└─────────────────────────────┘
```

### Team Mode (Example: 2 Teams, 4 Players)
```
┌─────────────────────────────┐
│ Game Mode                   │
│ [Singles] [Teams ✓]         │
├─────────────────────────────┤
│ Number of Teams (2-4)       │
│ [2✓] [3] [4]                │
├─────────────────────────────┤
│ Players by Team             │
│ ┌─────────────────────────┐ │
│ │ Team 1 (Green) 🟢       │ │
│ │ [👤 Alice ___________]  │ │
│ │ [👤 Bob   ___________]  │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ Team 2 (Gold) 🟡        │ │
│ │ [👤 Charlie _________]  │ │
│ │ [👤 Diana  _________]   │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

---

## Data Flow

```
GameSetupScreen
  ↓ User selects mode and count
  ↓ User enters player names
  ↓ User taps "Start Game"
  ↓
context.push('/game-scoring/{mode}', extra: {
  'players': ['Name1', 'Name2', ...],
  'isTeamMode': false/true,
  'teamCount': 2/3/4 (or null)
})
  ↓
GameScoringScreen
  ↓ Receives data in initState
  ↓ Initializes players and scores
  ↓ Displays scoring interface for all players
```

---

## Backward Compatibility

✅ **Fully backward compatible**
- GameSetupScreen works standalone (defaults to 2 players)
- GameScoringScreen accepts optional player data
- Old routes that don't pass player data still work
- Defaults to ['Player 1', 'Player 2'] if no data provided

---

## Next Steps to Consider

### Phase 2 - Team Scoring:
- Implement team score totals (sum of both players)
- Display team rankings during game
- Announce team winner on game end

### Phase 3 - Backend Integration:
- Save game configuration with team info to database
- Track team stats and records
- Implement team leaderboards

### Phase 4 - Advanced Features:
- Save favorite team configurations
- Team logos and custom colors
- Handicap per player/team
- Tournament bracket support

---

## Support

For issues or questions:
1. Check `IMPLEMENTATION_DETAILS.md` for code structure
2. Check `GAME_SETUP_GUIDE.md` for UI/UX details
3. Review test cases in "Testing Checklist"

