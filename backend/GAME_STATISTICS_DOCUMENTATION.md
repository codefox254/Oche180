"""
Game Results Integration Documentation

This module documents the comprehensive game statistics system for tracking and
analyzing darts game performance across all game modes.

BACKEND ENDPOINTS
=================

1. POST /api/games/submit_game_result/
   - Submit a complete game result with comprehensive statistics
   - Authentication: Token required
   - Request body:
     {
       "game_type": "501",  // Required: Game mode (501, 301, CRICKET, etc.)
       "is_training": false,  // Optional: Whether game is training
       "game_settings": {},  // Optional: Game-specific settings
       "players": [
         {
           "name": "Player Name",
           "final_score": 0,
           "final_position": 1,
           "is_winner": true,
           "is_current_user": true,
           "statistics": {},  // Optional: Additional stats
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
             "marks_per_round": null  // For Cricket
           }
         }
       ]
     }

   - Response (201 Created):
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

AUTOMATIC USER STATISTICS UPDATES
==================================

When a game result is submitted, the following user statistics are automatically updated:

1. UserStatistics:
   - total_games: Total number of games played
   - total_wins: Number of games won
   - total_losses: Number of games lost
   - win_percentage: Win/Total ratio
   - overall_average: Weighted average per dart
   - best_game_average: Best single-game average
   - total_180s: Total 180 scores hit
   - total_140_plus: Total 140+ scores hit
   - total_100_plus: Total 100+ scores hit
   - stats_by_mode: Dict containing per-game-mode statistics
     {
       "501": {
         "games": 10,
         "wins": 7,
         "average": 25.50,
         "best_average": 28.75
       }
     }

2. UserProfile:
   - total_xp: XP points (100 for win, 25 for participation)
   - level: Calculated from XP (configurable scaling)

3. GameStatistics (per player per game):
   - Detailed breakdown of every metric for that specific game

COMPREHENSIVE STATISTICS TRACKED
=================================

For each game, the following detailed metrics are captured:

Averaging Metrics:
- average_per_dart: Total score / Number of darts thrown
- average_per_round: Total score / Number of rounds

Throw Statistics:
- total_throws: Total darts thrown
- highest_score: Single highest-scoring round

High-Score Segments:
- count_180s: Number of 180 scores (3 x 20)
- count_140_plus: Number of rounds with 140+ points
- count_100_plus: Number of rounds with 100+ points

Finishing Statistics (for 501/301/etc):
- checkout_attempts: Number of times attempted to finish
- checkout_successes: Number of successful finishes
- checkout_percentage: Success rate for finishing

Special Metrics:
- marks_per_round: For Cricket mode (marks per round)

FRONTEND INTEGRATION
====================

1. GameResultsScreen:
   - Displays final standings with winner badge
   - Shows comprehensive statistics for current player
   - Animated entrance with scale transition
   - Shows all key metrics in easy-to-scan format

2. GameResultsService:
   - Handles HTTP requests to submit game results
   - Provides helper methods for formatting data
   - Includes error handling

3. Game Result Provider (Riverpod):
   - Manages game result submission state
   - Automatically refreshes user statistics
   - Handles async state for loading/error states

USAGE EXAMPLE
=============

// In your scoring screen widget
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

// Navigate to results screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => GameResultsScreen(
      gameResult: result['statistics'],
    ),
  ),
);

API ENDPOINTS FOR RELATED OPERATIONS
====================================

GET /api/games/recent/
- Get recent 10 games

GET /api/games/{id}/statistics/
- Get detailed statistics for a specific game

GET /api/stats/
- Get user statistics and personal bests (via user_stats app)

GAME MODES SUPPORTED
====================

Elimination Modes:
- 501, 301, 401, 701, 1001

Cricket Modes:
- CRICKET, CRICKET_CUTTHROAT, ENGLISH_CRICKET

Speed Games:
- AROUND_THE_CLOCK (ATC), SHANGHAI, KILLER

Point Games:
- HALVE_IT, BOBS_27, SCRAM, TIC_TAC_TOE, ALL_FIVES, MICKEY_MOUSE, GOTCHA

STATISTICS CALCULATION FORMULAS
================================

Average Per Dart:
- Formula: Total Score / Total Darts Thrown
- Example: 500 points / 18 darts = 27.78

Average Per Round:
- Formula: Total Score / Total Rounds
- Example: 500 points / 6 rounds = 83.33

Win Percentage:
- Formula: (Total Wins / Total Games) * 100
- Example: 7 wins / 10 games = 70%

Checkout Percentage:
- Formula: (Successful Checkouts / Checkout Attempts) * 100
- Example: 3 successes / 5 attempts = 60%

BEST PRACTICES
==============

1. Always validate that at least one player is marked as current_user
2. Calculate statistics on the frontend before sending (for UX responsiveness)
3. Store game ID from response for later reference
4. Refresh user statistics after game submission for accurate display
5. Use detailed_stats for all high-score segments for comprehensive tracking
6. Include is_training flag to distinguish practice games
7. Calculate averages with at least 1 decimal place precision
"""
