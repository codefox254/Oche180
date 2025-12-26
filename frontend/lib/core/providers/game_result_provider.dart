import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_results_service.dart';
import '../providers/auth_provider.dart';

// Game results service provider
final gameResultsServiceProvider = Provider((ref) {
  return GameResultsService();
});

// Notifier for game result submission
class GameResultNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    return {};
  }

  Future<void> submitGameResult({
    required String gameType,
    required bool isTraining,
    required Map<String, dynamic> gameSettings,
    required List<Map<String, dynamic>> players,
  }) async {
    state = const AsyncValue.loading();

    try {
      final authState = ref.read(authProvider);
      
      if (authState.token == null) {
        throw Exception('User not authenticated');
      }

      final gameResultsService = ref.read(gameResultsServiceProvider);
      final result = await gameResultsService.submitGameResult(
        token: authState.token!,
        gameType: gameType,
        isTraining: isTraining,
        gameSettings: gameSettings,
        players: players,
      );

      state = AsyncValue.data(result);
      
      // Invalidate auth provider to refresh statistics
      ref.invalidate(authProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Game result provider
final gameResultProvider = AsyncNotifierProvider<GameResultNotifier, Map<String, dynamic>>(() {
  return GameResultNotifier();
});

// Provider to track last game result
final lastGameResultProvider = AsyncNotifierProvider<GameResultNotifier, Map<String, dynamic>>(() {
  return GameResultNotifier();
});
