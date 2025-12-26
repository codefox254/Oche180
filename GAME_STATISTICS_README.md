# Comprehensive Game Statistics System

A complete darts game statistics tracking system that captures exhaustive game metrics and automatically syncs player data after every game.

## Overview

This system provides:
- **Exhaustive Darts Spectrum Statistics**: Track every meaningful metric from darts competitions
- **Automatic User Synchronization**: Game results instantly update player profiles
- **Comprehensive Metrics**: Averages, high-score segments, checkout rates, and more
- **Multi-Game Mode Support**: Works with all 14+ game modes (501, Cricket, etc.)
- **Beautiful UI**: Animated results screen with clear statistics display

## Backend Components

### Endpoints

#### POST `/api/games/submit_game_result/`

Submit a complete game result with comprehensive statistics. Automatically updates user profile and statistics.

**Authentication**: Token required

**Request Body**:
```json
{
  "game_type": "501",
  "is_training": false,
  "game_settings": {
    "starting_score": 501,
    "double_in": false,
    "double_out": true
  },
  "players": [
    {
      "name": "Player Name",
      "final_score": 0,
      "final_position": 1,
      "is_winner": true,
      "is_current_user": true,
      "statistics": {},
      "detailed_stats": {
        "total_throws": 45,
        "average_per_dart": 27.50,
        "average_per_round": 82.50,
        "checkout_attempts": 3,
        "checkout_successes": 1,
        "checkout_percentage": 33.33,
        "count_180s": 2,
        "count_140_plus": 8,
        "count_100_plus": 15,
        "highest_score": 180,
        "marks_per_round": null
      }
    }
  ]
}
```

**Response** (201 Created):
```json
{
  "game_id": 123,
  "message": "Game result recorded successfully",
  "statistics": {
    "game_type": "501",
    "is_training": false,
    "completed_at": "2025-12-26T21:00:00Z",
    "players_results": [
      {
        "name": "Player Name",
        "final_score": 0,
        "final_position": 1,
        "is_winner": true,
        "average_per_dart": 27.50,
        "average_per_round": 82.50,
        "total_throws": 45,
        "count_180s": 2,
        "count_140_plus": 8,
        "count_100_plus": 15,
        "highest_score": 180,
        "checkout_percentage": 33.33
      }
    ]
  }
}
```

## Statistics Tracked

### Per-Game Metrics

For each game, the following metrics are captured:

#### Averaging Metrics
- **average_per_dart**: Total score ÷ Number of darts
  - Example: 500 points ÷ 18 darts = 27.78 PPD
- **average_per_round**: Total score ÷ Number of rounds
  - Example: 500 points ÷ 6 rounds = 83.33 PPR

#### Throw Statistics
- **total_throws**: Total darts thrown in game
- **highest_score**: Best single round score

#### High-Score Segments
- **count_180s**: Number of 180 scores (3 × 20)
- **count_140_plus**: Number of rounds with 140+ points
- **count_100_plus**: Number of rounds with 100+ points

#### Finishing Statistics (501/301/etc)
- **checkout_attempts**: Attempts to finish game
- **checkout_successes**: Successful finishes
- **checkout_percentage**: Success rate for finishing

#### Special Metrics
- **marks_per_round**: Cricket mode (marks per round)

### User Profile Updates

After game submission, user statistics are automatically updated:

#### UserStatistics
- `total_games`: Total games played
- `total_wins`: Games won
- `total_losses`: Games lost
- `win_percentage`: Win rate (%)
- `overall_average`: Weighted average PPD
- `best_game_average`: Highest single-game PPD
- `total_180s`: Total 180s across all games
- `total_140_plus`: Total 140+ scores across all games
- `total_100_plus`: Total 100+ scores across all games
- `stats_by_mode`: Per-game-mode statistics

#### UserProfile
- `total_xp`: XP points (100 for win, 25 for participation)
- `level`: Calculated from XP

#### Example stats_by_mode Structure
```json
{
  "501": {
    "games": 10,
    "wins": 7,
    "average": 25.50,
    "best_average": 28.75
  },
  "CRICKET": {
    "games": 5,
    "wins": 3,
    "average": 12.30,
    "best_average": 15.20
  }
}
```

## Frontend Components

### GameResultsScreen

Beautiful animated screen displaying game results and comprehensive statistics.

**Features**:
- Animated entrance with scale transition
- Final standings with position badges
- Winner badge with trophy icon
- Comprehensive statistics breakdown
- High-score metrics visualization
- Game summary text

**Usage**:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => GameResultsScreen(
      gameResult: result['statistics'],
    ),
  ),
);
```

### GameResultsService

Service for submitting game results and formatting data.

**Methods**:
```dart
// Submit game result
Future<Map<String, dynamic>> submitGameResult({
  required String token,
  required String gameType,
  required bool isTraining,
  required Map<String, dynamic> gameSettings,
  required List<Map<String, dynamic>> players,
})

// Format player result
static Map<String, dynamic> formatPlayerResult({
  required String name,
  required int finalScore,
  int finalPosition = 1,
  bool isWinner = false,
  bool isCurrentUser = false,
  Map<String, dynamic>? statistics,
  Map<String, dynamic>? detailedStats,
})

// Format detailed statistics
static Map<String, dynamic> formatDetailedStats({
  required int totalThrows,
  required double averagePerDart,
  required double averagePerRound,
  int checkoutAttempts = 0,
  int checkoutSuccesses = 0,
  double checkoutPercentage = 0,
  int count180s = 0,
  int count140Plus = 0,
  int count100Plus = 0,
  int highestScore = 0,
  double? marksPerRound,
})
```

### Game Result Provider

Riverpod provider managing game submission state and user refresh.

```dart
// Watch submission state
final gameState = ref.watch(gameResultProvider);

// Submit game result
await ref.read(gameResultProvider.notifier).submitGameResult(
  gameType: '501',
  isTraining: false,
  gameSettings: {},
  players: [playerResult],
);
```

## Integration Guide

### 1. In Your Scoring Screen

When the game ends, calculate statistics and submit:

```dart
final result = await ref.read(gameResultProvider.notifier).submitGameResult(
  gameType: '501',
  isTraining: false,
  gameSettings: {'starting_score': 501},
  players: [
    GameResultsService.formatPlayerResult(
      name: 'Your Name',
      finalScore: 0,
      finalPosition: 1,
      isWinner: true,
      isCurrentUser: true,
      detailedStats: GameResultsService.formatDetailedStats(
        totalThrows: calculateTotalThrows(),
        averagePerDart: calculateAverage(),
        averagePerRound: calculateRoundAverage(),
        count180s: countHighScores(180),
        count140Plus: countHighScores(140),
        count100Plus: countHighScores(100),
        highestScore: getHighestRound(),
        checkoutPercentage: calculateCheckoutRate(),
      ),
    ),
  ],
);

// Navigate to results
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => GameResultsScreen(
      gameResult: result['statistics'],
    ),
  ),
);
```

### 2. Statistics Calculation on Frontend

Calculate these values while the game is in progress:

```dart
// Track during game
int totalDarts = 0;
int totalScore = 0;
int count180s = 0;
int count140Plus = 0;
int highestRound = 0;

// After round
totalDarts += 3;
totalScore += roundScore;
if (roundScore == 180) count180s++;
if (roundScore >= 140) count140Plus++;
if (roundScore > highestRound) highestRound = roundScore;

// Final calculations
double averagePerDart = totalScore / totalDarts;
double averagePerRound = totalScore / numberOfRounds;
```

### 3. Multi-Player Games

Submit results for all players:

```dart
final players = [
  GameResultsService.formatPlayerResult(
    name: 'Player 1',
    finalScore: 0,
    finalPosition: 1,
    isWinner: true,
    isCurrentUser: true,
    detailedStats: stats1,
  ),
  GameResultsService.formatPlayerResult(
    name: 'Player 2',
    finalScore: 50,
    finalPosition: 2,
    isWinner: false,
    detailedStats: stats2,
  ),
];

await ref.read(gameResultProvider.notifier).submitGameResult(
  gameType: '501',
  isTraining: false,
  gameSettings: {},
  players: players,
);
```

## Game Modes Supported

The system supports all game modes:

**Elimination Modes**: 501, 301, 401, 701, 1001
**Cricket**: CRICKET, CRICKET_CUTTHROAT, ENGLISH_CRICKET
**Speed Games**: AROUND_THE_CLOCK, SHANGHAI, KILLER
**Point Games**: HALVE_IT, BOBS_27, SCRAM, TIC_TAC_TOE, ALL_FIVES, MICKEY_MOUSE, GOTCHA

## Calculation Formulas

### Average Per Dart (PPD)
```
PPD = Total Score / Total Darts Thrown
Example: 500 / 18 = 27.78 PPD
```

### Average Per Round
```
Average = Total Score / Total Rounds
Example: 500 / 6 = 83.33 PPR
```

### Win Percentage
```
Win % = (Total Wins / Total Games) × 100
Example: 7 / 10 × 100 = 70%
```

### Checkout Percentage
```
Checkout % = (Successful Checkouts / Checkout Attempts) × 100
Example: 3 / 5 × 100 = 60%
```

## Best Practices

1. **Validate Data**: Ensure at least one player is marked `is_current_user`
2. **Calculate on Frontend**: Compute statistics while game is in progress for better UX
3. **Store Game ID**: Keep game ID for future reference and replay
4. **Refresh After Submission**: Automatically refresh user stats after submission
5. **Precision**: Use at least 2 decimal places for averages
6. **Training Mode**: Mark practice games with `is_training: true` if needed
7. **Complete Data**: Always include detailed_stats for comprehensive tracking

## Error Handling

```dart
final gameState = ref.watch(gameResultProvider);

gameState.when(
  data: (result) {
    // Success - navigate to results
    Navigator.push(...);
  },
  loading: () {
    // Show loading indicator
    return CircularProgressIndicator();
  },
  error: (error, stackTrace) {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $error')),
    );
  },
);
```

## File Structure

```
Backend:
├── games/
│   ├── views.py (updated with submit_game_result)
│   ├── serializers.py (new serializers)
│   └── models.py (GameStatistics)
├── user_stats/
│   └── models.py (UserStatistics)
└── accounts/
    └── models.py (UserProfile updates)

Frontend:
├── lib/features/games/presentation/
│   ├── game_results_screen.dart
│   └── scoring_example.dart
├── lib/core/services/
│   └── game_results_service.dart
└── lib/core/providers/
    └── game_result_provider.dart
```

## Next Steps

1. Connect scoring screen to submit game results
2. Add user stats display to home/profile screen
3. Create personal bests display
4. Add game history/replay feature
5. Implement leaderboard system
6. Add achievement system
7. Create streak tracking

## Support

For detailed API documentation, see `GAME_STATISTICS_DOCUMENTATION.md`
