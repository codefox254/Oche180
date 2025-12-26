import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/game_results_service.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';

// Game results service provider
final gameResultsServiceProvider = Provider((ref) {
  return GameResultsService();
});

// Notifier for game result submission
class GameResultNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final GameResultsService _gameResultsService;
  final AuthService _authService;
  final Ref _ref;

  GameResultNotifier(
    this._gameResultsService,
    this._authService,
    this._ref,
  ) : super(const AsyncValue.data({}));

  Future<void> submitGameResult({
    required String gameType,
    required bool isTraining,
    required Map<String, dynamic> gameSettings,
    required List<Map<String, dynamic>> players,
  }) async {
    state = const AsyncValue.loading();

    try {
      final authState = _ref.read(authProvider);
      
      if (authState.token == null) {
        throw Exception('User not authenticated');
      }

      final result = await _gameResultsService.submitGameResult(
        token: authState.token!,
        gameType: gameType,
        isTraining: isTraining,
        gameSettings: gameSettings,
        players: players,
      );

      state = AsyncValue.data(result);
      
      // Refresh user statistics after game submission
      _ref.refresh(authProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Game result provider
final gameResultProvider = StateNotifierProvider<
    GameResultNotifier,
    AsyncValue<Map<String, dynamic>>>((ref) {
  return GameResultNotifier(
    ref.watch(gameResultsServiceProvider),
    ref.watch(Provider((ref) => AuthService())),
    ref,
  );
});

// Provider to track last game result
final lastGameResultProvider =
    StateNotifierProvider<GameResultNotifier, AsyncValue<Map<String, dynamic>>>(
  (ref) {
    return GameResultNotifier(
      ref.watch(gameResultsServiceProvider),
      ref.watch(Provider((ref) => AuthService())),
      ref,
    );
  },
);
