import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_landing_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/games/presentation/game_modes_screen.dart';
import '../features/games/presentation/game_setup_screen.dart';
import '../features/games/presentation/bull_to_start_screen.dart';
import '../features/games/presentation/game_scoring_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/training/presentation/training_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';
import '../features/rules/presentation/game_rules_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/onboarding/presentation/splash_screen.dart';
import '../features/tournaments/screens/tournaments_screen.dart';
import '../features/tournaments/screens/live_tournaments_screen.dart';
import '../features/tournaments/screens/create_tournament_screen.dart';
import '../features/tournaments/screens/tournament_detail_screen.dart';
import '../features/tournaments/screens/manage_entries_screen.dart';

class AppRoute {
  const AppRoute._(this.name, this.path);

  final String name;
  final String path;

  static const splash = AppRoute._('splash', '/');
  static const home = AppRoute._('home', '/home');
  static const authLanding = AppRoute._('auth-landing', '/auth');
  static const login = AppRoute._('login', '/auth/login');
  static const signup = AppRoute._('signup', '/auth/signup');
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
        path: AppRoute.login.path,
        name: AppRoute.login.name,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoute.signup.path,
        name: AppRoute.signup.name,
        builder: (context, state) => const SignupScreen(),
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
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
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
      GoRoute(
        path: '/tournaments',
        builder: (context, state) => const LiveTournamentsScreen(),
      ),
      GoRoute(
        path: '/tournaments/list',
        builder: (context, state) => const TournamentsScreen(),
      ),
      GoRoute(
        path: '/tournaments/create',
        builder: (context, state) => const CreateTournamentScreen(),
      ),
      GoRoute(
        path: '/tournaments/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return TournamentDetailScreen(tournamentId: id);
        },
      ),
      GoRoute(
        path: '/tournaments/:id/manage',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return ManageEntriesScreen(tournamentId: id);
        },
      ),
    ],
  );
});
