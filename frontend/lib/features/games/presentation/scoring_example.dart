import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/game_results_service.dart';
import '../../../core/providers/game_result_provider.dart';
import 'game_results_screen.dart';

/// Example usage of the game results system in a scoring screen
class ScoringScreenExample extends ConsumerStatefulWidget {
  const ScoringScreenExample({Key? key}) : super(key: key);

  @override
  ConsumerState<ScoringScreenExample> createState() =>
      _ScoringScreenExampleState();
}

class _ScoringScreenExampleState extends ConsumerState<ScoringScreenExample> {
  /// Finish game and submit results
  Future<void> _finishGame({
    required String playerName,
    required int finalScore,
    required bool isWinner,
    required double averagePerDart,
    required double averagePerRound,
    required int totalThrows,
    required int count180s,
    required int count140Plus,
    required int count100Plus,
    required int highestScore,
    required double checkoutPercentage,
    required int checkoutSuccesses,
    required int checkoutAttempts,
  }) async {
    try {
      // Format detailed statistics
      final detailedStats = GameResultsService.formatDetailedStats(
        totalThrows: totalThrows,
        averagePerDart: averagePerDart,
        averagePerRound: averagePerRound,
        count180s: count180s,
        count140Plus: count140Plus,
        count100Plus: count100Plus,
        highestScore: highestScore,
        checkoutPercentage: checkoutPercentage,
        checkoutAttempts: checkoutAttempts,
        checkoutSuccesses: checkoutSuccesses,
      );

      // Format player result
      final playerResult = GameResultsService.formatPlayerResult(
        name: playerName,
        finalScore: finalScore,
        finalPosition: 1,
        isWinner: isWinner,
        isCurrentUser: true,
        detailedStats: detailedStats,
      );

      // Submit game result
      await ref.read(gameResultProvider.notifier).submitGameResult(
        gameType: '501', // Change based on game type
        isTraining: false,
        gameSettings: {
          'starting_score': 501,
          'double_in': false,
          'double_out': true,
        },
        players: [playerResult],
      );

      // Get the result
      final state = ref.read(gameResultProvider);
      state.whenData((result) {
        // Navigate to results screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GameResultsScreen(
              gameResult: result['statistics'] ?? {},
            ),
          ),
        );
      }).whenError((error, stackTrace) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.toString()}')),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting game: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameResultState = ref.watch(gameResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scoring Example'),
      ),
      body: Center(
        child: gameResultState.when(
          data: (_) => const Text('Game submitted successfully'),
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) => Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Example: Finish a game with sample data
          _finishGame(
            playerName: 'John Doe',
            finalScore: 0, // 501 checkout
            isWinner: true,
            averagePerDart: 27.50,
            averagePerRound: 82.50,
            totalThrows: 45,
            count180s: 2,
            count140Plus: 8,
            count100Plus: 15,
            highestScore: 180,
            checkoutPercentage: 33.33,
            checkoutSuccesses: 1,
            checkoutAttempts: 3,
          );
        },
        tooltip: 'Finish Game',
        child: const Icon(Icons.check),
      ),
    );
  }
}

// Example with multiple players
class MultiPlayerGameExample extends ConsumerStatefulWidget {
  const MultiPlayerGameExample({Key? key}) : super(key: key);

  @override
  ConsumerState<MultiPlayerGameExample> createState() =>
      _MultiPlayerGameExampleState();
}

class _MultiPlayerGameExampleState extends ConsumerState<MultiPlayerGameExample> {
  Future<void> _finishMultiPlayerGame() async {
    try {
      // Format stats for each player
      final players = [
        GameResultsService.formatPlayerResult(
          name: 'You',
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
        GameResultsService.formatPlayerResult(
          name: 'Opponent 1',
          finalScore: 50,
          finalPosition: 2,
          isWinner: false,
          detailedStats: GameResultsService.formatDetailedStats(
            totalThrows: 48,
            averagePerDart: 24.75,
            averagePerRound: 74.25,
            count180s: 1,
            count140Plus: 5,
            count100Plus: 12,
            highestScore: 160,
            checkoutPercentage: 0,
          ),
        ),
        GameResultsService.formatPlayerResult(
          name: 'Opponent 2',
          finalScore: 100,
          finalPosition: 3,
          isWinner: false,
          detailedStats: GameResultsService.formatDetailedStats(
            totalThrows: 52,
            averagePerDart: 22.10,
            averagePerRound: 66.30,
            count180s: 0,
            count140Plus: 3,
            count100Plus: 8,
            highestScore: 140,
            checkoutPercentage: 0,
          ),
        ),
      ];

      // Submit multi-player game
      await ref.read(gameResultProvider.notifier).submitGameResult(
        gameType: '501',
        isTraining: false,
        gameSettings: {'starting_score': 501},
        players: players,
      );

      // Show results
      final state = ref.read(gameResultProvider);
      state.whenData((result) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GameResultsScreen(
              gameResult: result['statistics'] ?? {},
            ),
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multi-Player Example')),
      body: const Center(child: Text('Multi-player game example')),
      floatingActionButton: FloatingActionButton(
        onPressed: _finishMultiPlayerGame,
        child: const Icon(Icons.check),
      ),
    );
  }
}
