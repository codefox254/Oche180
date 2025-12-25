# Game Setup Feature - User Guide

## Overview
The enhanced game setup screen now supports:
- **1-6 individual players** (Singles mode)
- **2-4 teams** with 2 players each (Team mode)
- **Custom player names** for all configurations

---

## User Flow

### Starting a Game

```
1. Home Screen
   ↓
   [Play Button]
   ↓
2. Game Modes Screen
   ↓
   [Select Game Mode: 501, Cricket, or Around the Clock]
   ↓
3. Game Setup Screen (ENHANCED) ← YOU ARE HERE
   ├─ Step 1: Choose Game Mode
   │  └─ [Singles] or [Teams (2v2)]
   │
   ├─ Step 2: Select Player/Team Count
   │  ├─ Singles: Choose 1-6 players
   │  └─ Teams: Choose 2-4 teams
   │
   ├─ Step 3: Enter Player Names
   │  ├─ Singles: 1-6 input fields
   │  └─ Teams: Organized by color-coded teams
   │
   └─ [Start Game Button]
   ↓
4. Game Scoring Screen
   └─ Displays all players with scores
```

---

## Mode 1: Singles (1-6 Players)

### UI Layout:

```
┌────────────────────────────────────────────┐
│  Setup Game                                │
│  501                                       │
├────────────────────────────────────────────┤
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │  Game Mode                           │  │
│  │  [Singles ✓]  [Teams (2v2)]          │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │  Number of Players (1-6)             │  │
│  │  [1]  [2]  [3]  [4]  [5]  [6]        │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │  Player Names                        │  │
│  │  [👤 Player 1     ____________]      │  │
│  │  [👤 Player 2     ____________]      │  │
│  │  [👤 Player 3     ____________]      │  │
│  │  ...                                 │  │
│  │  [👤 Player N     ____________]      │  │
│  └──────────────────────────────────────┘  │
│                                            │
│          [START GAME →]                    │
└────────────────────────────────────────────┘
```

### Example: 3-Player Game

```
Player Selection: Click [3]
Result:
- Player 1 Name: (editable)
- Player 2 Name: (editable)
- Player 3 Name: (editable)

Scoring screen will show:
┌─────────┬─────────┬─────────┐
│ Player1 │ Player2 │ Player3 │
│ Score1  │ Score2  │ Score3  │
└─────────┴─────────┴─────────┘
```

---

## Mode 2: Teams (2-4 Teams, 2 Players Per Team)

### UI Layout:

```
┌────────────────────────────────────────────┐
│  Setup Game                                │
│  501                                       │
├────────────────────────────────────────────┤
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │  Game Mode                           │  │
│  │  [Singles]  [Teams (2v2) ✓]          │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │  Number of Teams (2-4)               │  │
│  │  [2]  [3]  [4]                       │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │  Players by Team                     │  │
│  │                                      │  │
│  │  ┌──────────────────────────────┐   │  │
│  │  │ Team 1 (Primary Color)   🔷  │   │  │
│  │  │ [👤 Player 1 ________]      │   │  │
│  │  │ [👤 Player 2 ________]      │   │  │
│  │  └──────────────────────────────┘   │  │
│  │                                      │  │
│  │  ┌──────────────────────────────┐   │  │
│  │  │ Team 2 (Accent Color)    🔶  │   │  │
│  │  │ [👤 Player 3 ________]      │   │  │
│  │  │ [👤 Player 4 ________]      │   │  │
│  │  └──────────────────────────────┘   │  │
│  │                                      │  │
│  │  ┌──────────────────────────────┐   │  │
│  │  │ Team 3 (Secondary Color) 🟡  │   │  │
│  │  │ [👤 Player 5 ________]      │   │  │
│  │  │ [👤 Player 6 ________]      │   │  │
│  │  └──────────────────────────────┘   │  │
│  │                                      │  │
│  └──────────────────────────────────────┘  │
│                                            │
│          [START GAME →]                    │
└────────────────────────────────────────────┘
```

### Example: 2v2 Game (2 Teams, 4 Players Total)

```
Team Selection: Click [2]
Result:
  Team 1:
  - Player 1 (custom name)
  - Player 2 (custom name)
  
  Team 2:
  - Player 3 (custom name)
  - Player 4 (custom name)

Scoring will track:
┌──────────────────┬──────────────────┐
│     TEAM 1       │     TEAM 2       │
├──────────────────┼──────────────────┤
│ Player 1: Score1 │ Player 3: Score3 │
│ Player 2: Score2 │ Player 4: Score4 │
│ TOTAL: X         │ TOTAL: Y         │
└──────────────────┴──────────────────┘
```

---

## Key Features

### 1. **Player Naming**
- Default names: "Player 1", "Player 2", etc.
- Click any input field to customize
- Names appear in scoring screen exactly as entered

### 2. **Mode Toggle**
- Switch between Singles/Teams with one tap
- All player data preserved within current mode
- Switching modes resets player count to default

### 3. **Color-Coded Teams**
- **Team 1**: Primary Green (#1B5E20)
- **Team 2**: Accent Gold (#FFC107)
- **Team 3**: Secondary Teal (#00BCD4)
- **Team 4**: Error Red (#F44336)

### 4. **Dynamic UI**
- Number selector shows only valid options for current mode
- Input fields dynamically added/removed
- Responsive to portrait and landscape layouts

---

## Data Passed to Scoring Screen

When "Start Game" is clicked, the following data is sent:

```dart
{
  'players': ['Player 1', 'Player 2', ...],  // Custom player names
  'isTeamMode': false,                        // true for team mode
  'teamCount': null,                          // null for singles, 2-4 for teams
}
```

The GameScoringScreen uses this data to:
- Initialize score tracking for each player
- Display correct player names in header
- Determine scoring rules (individual vs team)

---

## Technical Implementation

### Components:
- **GameSetupScreen**: Main widget with mode toggle and player config
- **_TeamPlayersList**: Helper widget for team layout with color coding
- **_SectionCard**: Glassmorphism card wrapper for UI sections

### State Variables:
```dart
bool _isTeamMode;              // Toggle between modes
int _playerCount;              // 1-6 for singles
int _teamCount;                // 2-4 for teams
List<TextEditingController> _playerControllers;  // Dynamic input fields
```

### Methods:
```dart
_updatePlayerCount(int count)  // Handle singles mode selection
_updateTeamCount(int count)    // Handle team mode selection
_toggleTeamMode()              // Switch modes and reset data
```

---

## Future Enhancements

1. **Team Logo Upload**: Let teams pick custom colors/logos
2. **Player Stats**: Show player history before game starts
3. **Preset Teams**: Save favorite team configurations
4. **Difficulty Levels**: Set handicap per player/team
5. **Server Sync**: Save game config to backend

