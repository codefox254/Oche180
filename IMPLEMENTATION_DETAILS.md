# Implementation Details - Game Setup Enhancement

## File Modifications

### 1. GameSetupScreen - Complete Feature List

**File**: `frontend/lib/features/games/presentation/game_setup_screen.dart`

#### State Variables Added:
```dart
bool _isTeamMode = false;           // Singles or Teams toggle
int _playerCount = 1;               // 1-6 for singles mode
int _teamCount = 2;                 // 2-4 for team mode
```

#### New Methods:

**1. `_updatePlayerCount(int count)`**
- Updates player count for singles mode (1-6)
- Dynamically adds/removes TextEditingControllers
- Each controller initialized with "Player N" default text

**2. `_updateTeamCount(int count)`**
- Updates team count (2-4 teams)
- Automatically creates 2 players per team
- Adds/removes controllers: `teamCount * 2` total players

**3. `_toggleTeamMode()`**
- Switches between Singles and Team modes
- Preserves player names when toggling (if within bounds)
- Resets to defaults: Singles = 1 player, Teams = 2 teams

#### UI Sections:

**Section 1: Game Mode Toggle**
```dart
// Two-button toggle: Singles | Teams
// Displays with Icons (person, group)
// Updates _isTeamMode boolean
```

**Section 2: Player/Team Count Selector**
```dart
// Singles Mode: [1] [2] [3] [4] [5] [6] buttons
// Teams Mode: [2] [3] [4] buttons
// Uses gradient highlight for selected option
```

**Section 3: Player Names Input**
```dart
// Singles: List of TextFormFields (1-6)
// Teams: Organized by teams with color headers
//   - Team 1 (Primary Green)
//   - Team 2 (Accent Gold)
//   - etc.
```

#### Navigation:
```dart
context.push(
  '/game-scoring/${widget.gameMode}',
  extra: {
    'players': playerNames,      // List<String>
    'isTeamMode': _isTeamMode,   // bool
    'teamCount': _teamCount,     // int (only if isTeamMode=true)
  },
);
```

---

### 2. GameScoringScreen - Enhanced Constructor

**File**: `frontend/lib/features/games/presentation/game_scoring_screen.dart`

#### Constructor Updated:
```dart
class GameScoringScreen extends StatefulWidget {
  const GameScoringScreen({
    super.key,
    required this.gameMode,
    this.players,                    // Optional: List<String>
    this.isTeamMode = false,         // Optional: bool
    this.teamCount,                  // Optional: int
  });

  final String gameMode;
  final List<String>? players;       // Passed from GameSetupScreen
  final bool isTeamMode;
  final int? teamCount;
}
```

#### State Initialization:
```dart
@override
void initState() {
  super.initState();
  
  // Use passed players or default
  if (widget.players != null && widget.players!.isNotEmpty) {
    players = widget.players!;
  } else {
    players = ['Player 1', 'Player 2'];
  }
  
  // Initialize score map from players
  scores = {for (var p in players) p: 501};
  
  _tabController = TabController(length: 3, vsync: this);
}
```

---

### 3. New Widget: _TeamPlayersList

**Purpose**: Renders team configuration with color-coded sections

```dart
class _TeamPlayersList extends StatelessWidget {
  final int teamCount;
  final List<TextEditingController> playerControllers;

  // Renders:
  // - Team Header (with color)
  // - 2 TextFormFields per team
  // - Color-coded borders and backgrounds
  
  // Colors used:
  // [Primary Green, Accent Gold, Secondary Teal, Error Red]
}
```

#### Features:
- Loops through `teamCount` (2-4 teams)
- For each team, displays 2 players
- Each team uses a different color from theme
- Container with team color background and border
- TextFormField icons match team color

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────┐
│ GameSetupScreen                                     │
│                                                     │
│ 1. User selects mode (Singles or Teams)            │
│    └─> _toggleTeamMode()                           │
│        └─> Sets _isTeamMode, resets controllers   │
│                                                     │
│ 2. User selects count (1-6 for Singles, 2-4 Teams)│
│    └─> _updatePlayerCount() OR                     │
│        _updateTeamCount()                          │
│        └─> Creates/destroys TextEditingControllers │
│                                                     │
│ 3. User enters names in TextFormFields             │
│    └─> Values stored in controller.text            │
│                                                     │
│ 4. User taps "Start Game"                          │
│    └─> Extracts all names from controllers         │
│        └─> context.push() with 'extra' data       │
│            └─> Passes to GameScoringScreen        │
│                                                     │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│ GameScoringScreen                                   │
│                                                     │
│ 1. initState() receives 'extra' data               │
│    └─> Initializes `players` from widget.players   │
│        └─> Creates `scores` map for tracking      │
│                                                     │
│ 2. _ScoreHeader widget uses players list           │
│    └─> Displays each player's current score       │
│        └─> Highlights current player's turn       │
│                                                     │
│ 3. Scoring tabs available for all players         │
│    └─> Manual keypad (0-9)                        │
│    └─> Quick scores (common darts values)         │
│    └─> Dartboard (segment selection)              │
│                                                     │
│ 4. Submit updates scores and rotation              │
│    └─> Moves to next player in rotation           │
│        └─> (currentPlayerIndex + 1) % players.length
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## UI Component Hierarchy

### GameSetupScreen Widget Tree:
```
Scaffold
├── Container (gradient background)
└── SafeArea
    └── Column
        ├── AppBar Row
        │   ├── Back Button
        │   ├── Icon
        │   ├── Title
        │   └── Subtitle
        │
        ├── SingleChildScrollView
        │   └── Column
        │       ├── _SectionCard (Game Mode)
        │       │   └── Row
        │       │       ├── GestureDetector [Singles]
        │       │       └── GestureDetector [Teams]
        │       │
        │       ├── _SectionCard (Player/Team Count)
        │       │   └── Wrap or Row
        │       │       └── [1-6] or [2-4] buttons
        │       │
        │       └── _SectionCard (Player Names)
        │           └── Column or _TeamPlayersList
        │               └── TextFormField × N
        │
        └── Container (bottom button)
            └── ElevatedButton [Start Game]
```

### _TeamPlayersList Widget Tree:
```
Column (for each team)
├── Container (team background)
│   └── Column
│       ├── Text (Team N header)
│       └── Column
│           └── TextFormField × 2
└── [repeat for each team]
```

---

## Color Coding System

Used for visual differentiation of teams:

| Team | Color | Hex Value | Usage |
|------|-------|-----------|-------|
| Team 1 | Primary Green | #1B5E20 | Main theme color |
| Team 2 | Accent Gold | #FFC107 | Secondary theme color |
| Team 3 | Secondary Teal | #00BCD4 | Tertiary accent |
| Team 4 | Error Red | #F44336 | Warning/Error color |

Each team's borders, backgrounds, and icons use their assigned color.

---

## Controller Management

### Creation:
```dart
_playerControllers.add(
  TextEditingController(text: 'Player ${_playerControllers.length + 1}')
);
```

### Removal:
```dart
_playerControllers.removeLast().dispose();
```

### Access:
```dart
final playerNames = _playerControllers
    .take(_isTeamMode ? _teamCount * 2 : _playerCount)
    .map((c) => c.text)
    .toList();
```

### Cleanup:
```dart
@override
void dispose() {
  for (var controller in _playerControllers) {
    controller.dispose();
  }
  super.dispose();
}
```

---

## Validation & Error Handling

Currently implemented:
- ✅ Auto-limit count selections (buttons only allow valid options)
- ✅ Default names for empty fields
- ✅ Memory management (controllers disposed properly)

Ready for implementation:
- [ ] Validation: Prevent duplicate player names
- [ ] Validation: Require at least 1 character in names
- [ ] Snackbar: Show confirmation before starting
- [ ] Error states: Handle navigation failures

---

## Testing Checklist

- [ ] Switch from Singles to Teams mode
- [ ] Switch from Teams to Singles mode
- [ ] Adjust player count in Singles (1→6, 6→1)
- [ ] Adjust team count in Teams (2→4, 4→2)
- [ ] Edit player names and verify passed to scoring
- [ ] Start game with 1 player (verify scoring adjusts)
- [ ] Start game with 6 players (verify all names shown)
- [ ] Start game with teams (verify team display)
- [ ] Verify back button returns to game modes screen
- [ ] Verify memory cleanup (no leaked controllers)

