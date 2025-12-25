import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_landing_screen.dart';
import '../features/games/presentation/game_modes_screen.dart';
import '../features/games/presentation/game_setup_screen.dart';
import '../features/games/presentation/bull_to_start_screen.dart';
import '../features/games/presentation/game_scoring_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/training/presentation/training_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';
import '../features/rules/presentation/game_rules_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/onboarding/presentation/splash_screen.dart';

class AppRoute {
  const AppRoute._(this.name, this.path);

  final String name;
  final String path;

  static const splash = AppRoute._('splash', '/');
  static const home = AppRoute._('home', '/home');
  static const authLanding = AppRoute._('auth-landing', '/auth');
  static const gameModes = AppRoute._('game-modes', '/game-modes');
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.home.path,
    routes: [
      GoRoute(
        path: AppRoute.splash.path,
        name: AppRoute.splash.name,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoute.home.path,
        name: AppRoute.home.name,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoute.authLanding.path,
        name: AppRoute.authLanding.name,
        builder: (context, state) => const AuthLandingScreen(),
      ),
      GoRoute(
        path: AppRoute.gameModes.path,
        name: AppRoute.gameModes.name,
        builder: (context, state) => const GameModesScreen(),
      ),
      GoRoute(
        path: '/game-setup/:mode',
        builder: (context, state) {
          final mode = state.pathParameters['mode'] ?? '501';
          return GameSetupScreen(gameMode: mode);
        },
      ),
      GoRoute(
        path: '/bull-start',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final players = (extra?['players'] as List<dynamic>?)?.cast<String>() ?? [];
          final gameMode = extra?['gameMode'] as String? ?? '501';
          final matchConfig = extra?['matchConfig'] as Map<String, dynamic>? ?? {};
          return BullToStartScreen(
            players: players,
            gameMode: gameMode,
            matchConfig: matchConfig,
          );
        },
      ),
      GoRoute(
        path: '/game-scoring/:mode',
        builder: (context, state) {
          final mode = state.pathParameters['mode'] ?? '501';
          final extra = state.extra as Map<String, dynamic>?;
          return GameScoringScreen(
            gameMode: mode,
            players: extra?['players'] as List<String>?,
            isTeamMode: extra?['isTeamMode'] as bool? ?? false,
            teamCount: extra?['teamCount'] as int?,
            matchFormat: extra?['matchFormat'] as String? ?? 'single',
            bestOfLegs: extra?['bestOfLegs'] as int?,
            setsToWin: extra?['setsToWin'] as int?,
            legsPerSet: extra?['legsPerSet'] as int?,
            bullWinner: extra?['bullWinner'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/training',
        builder: (context, state) => const TrainingScreen(),
      ),
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/game-rules',
        builder: (context, state) => const GameRulesScreen(),
      ),
    ],
  );
});
