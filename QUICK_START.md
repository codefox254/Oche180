# Game Statistics System - Quick Start Guide

## Overview
You now have a complete game statistics system that tracks exhaustive darts metrics and automatically syncs player data after every game.

## What Was Built

### Backend (Django)
- **New Endpoint**: `POST /api/games/submit_game_result/`
- **Auto-Updates**: UserStatistics, UserProfile, GameStatistics
- **Calculates**: Averages, win rates, high-score counts, per-game-mode stats
- **XP System**: 100 points for win, 25 for participation

### Frontend (Flutter)
- **GameResultsScreen**: Beautiful animated results display
- **GameResultsService**: HTTP integration with helper methods
- **Game Result Provider**: Riverpod state management
- **Complete Examples**: Single and multi-player game submissions

## Statistics Tracked

Each game automatically tracks:
- Average per dart (PPD)
- Average per round
- Total throws
- 180 count, 140+ count, 100+ count
- Highest score, Checkout percentage
- Win/loss results
- Game-mode specific stats

## Getting Started (5 minutes)

### 1. In Your Scoring Screen

Make it a `ConsumerStatefulWidget`:
```dart
class ScoringScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends ConsumerState<ScoringScreen> {
  // ... existing code ...
}
```

### 2. When Game Ends

Collect the statistics and submit:
```dart
// Calculate your stats during the game
int totalDarts = 45;
int totalScore = 1237;
double avgPerDart = totalScore / totalDarts; // 27.49

// Submit when game ends
await ref.read(gameResultProvider.notifier).submitGameResult(
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
        totalThrows: totalDarts,
        averagePerDart: avgPerDart,
        averagePerRound: totalScore / numberOfRounds,
        count180s: countOf180s,
        count140Plus: countOf140Plus,
        count100Plus: countOf100Plus,
        highestScore: maxRoundScore,
        checkoutPercentage: (successfulCheckouts / checkoutAttempts) * 100,
      ),
    ),
  ],
);
```

### 3. Show Results

```dart
final gameState = ref.watch(gameResultProvider);

gameState.whenData((result) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GameResultsScreen(
        gameResult: result['statistics'],
      ),
    ),
  );
});
```

## Available Helper Methods

```dart
// Format detailed statistics
GameResultsService.formatDetailedStats(
  totalThrows: 45,
  averagePerDart: 27.50,
  averagePerRound: 82.50,
  count180s: 2,
  count140Plus: 8,
  count100Plus: 15,
  highestScore: 180,
  checkoutPercentage: 33.33,
)

// Format player result
GameResultsService.formatPlayerResult(
  name: 'Player Name',
  finalScore: 0,
  finalPosition: 1,
  isWinner: true,
  isCurrentUser: true,
  detailedStats: {...}
)
```

## API Endpoint

```
POST /api/games/submit_game_result/
Header: Authorization: Token <auth_token>

Response: {
  "game_id": 123,
  "message": "Game result recorded successfully",
  "statistics": {
    "game_type": "501",
    "completed_at": "2025-12-26T21:00:00Z",
    "players_results": [...]
  }
}
```

## User Stats Auto-Updated

After submission, your user profile automatically gets:
- `total_games` += 1
- `total_wins` += 1 (if you won)
- `overall_average` = weighted average
- `best_game_average` = best single game
- `total_180s` += your 180 count
- `total_xp` += 100 (win) or 25 (participation)

## Supported Game Modes

- 501, 301, 401, 701, 1001
- CRICKET, CRICKET_CUTTHROAT, ENGLISH_CRICKET
- AROUND_THE_CLOCK, SHANGHAI, KILLER
- HALVE_IT, BOBS_27, SCRAM, TIC_TAC_TOE, ALL_FIVES, MICKEY_MOUSE, GOTCHA

## Error Handling

```dart
final gameState = ref.watch(gameResultProvider);

gameState.when(
  data: (result) => GameResultsScreen(gameResult: result['statistics']),
  loading: () => CircularProgressIndicator(),
  error: (error, st) => Text('Error: $error'),
);
```

## Testing

Test with sample data:
```dart
await ref.read(gameResultProvider.notifier).submitGameResult(
  gameType: '501',
  isTraining: true,  // Mark as practice
  gameSettings: {},
  players: [
    GameResultsService.formatPlayerResult(
      name: 'Test Player',
      finalScore: 0,
      isWinner: true,
      isCurrentUser: true,
      detailedStats: GameResultsService.formatDetailedStats(
        totalThrows: 45,
        averagePerDart: 27.50,
        averagePerRound: 82.50,
        count180s: 2,
        count140Plus: 8,
        count100Plus: 15,
        highestScore: 180,
        checkoutPercentage: 33.33,
      ),
    ),
  ],
);
```

## Files Modified/Created

**Backend**:
- `games/views.py` - Added submit_game_result action
- `games/serializers.py` - Added new serializers

**Frontend**:
- `lib/features/games/presentation/game_results_screen.dart` - Results display
- `lib/core/services/game_results_service.dart` - HTTP service
- `lib/core/providers/game_result_provider.dart` - Riverpod provider
- `lib/features/games/presentation/scoring_example.dart` - Code examples

**Documentation**:
- `GAME_STATISTICS_README.md` - Full guide
- `GAME_STATISTICS_DOCUMENTATION.md` - API reference
- This file - Quick start

## Next Steps

1. ✅ Copy the integration code to your scoring screen
2. ✅ Calculate statistics during gameplay
3. ✅ Test the end-to-end flow
4. ✅ Add user stats display to home/profile screen
5. ✅ Implement game history feature

## Support

See complete documentation in:
- `GAME_STATISTICS_README.md` - Comprehensive guide
- `GAME_STATISTICS_DOCUMENTATION.md` - API reference  
- `scoring_example.dart` - Code examples

## Summary

You now have:
- ✅ Comprehensive game statistics tracking
- ✅ Automatic user profile updates
- ✅ Beautiful results screen
- ✅ Multi-player support
- ✅ All 14+ game modes supported
- ✅ XP and leveling system
- ✅ Complete documentation and examples

**Ready to integrate into your scoring screen!**
