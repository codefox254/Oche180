import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_design.dart';

class GameModesScreen extends StatelessWidget {
  const GameModesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modes = [
      _GameMode('501', 'Start at 501 and race to exactly zero. Must finish with a double!', Icons.filter_1, AppColors.primary, '501'),
      _GameMode('301', 'Fast-paced version of 501 with lower starting score.', Icons.filter_2, AppColors.primary, '301'),
      _GameMode('401', 'Mid-range game. Balance speed with accuracy.', Icons.filter_3, AppColors.primary, '401'),
      _GameMode('701', 'Extended endurance test. Build consistency over longer play.', Icons.filter_4, AppColors.primary, '701'),
      _GameMode('1001', 'Ultimate marathon game. Ultimate stamina challenge!', Icons.numbers, AppColors.primary, '1001'),
      _GameMode('Cricket', 'Close numbers 15-20 and Bull first. Strategy meets skill.', Icons.grid_on, AppColors.secondary, 'CRICKET'),
      _GameMode('Cricket Cut-Throat', 'Score against opponents. One wrong move helps them!', Icons.whatshot, AppColors.accent, 'CRICKET_CUTTHROAT'),
      _GameMode('English Cricket', 'Pure closing race. No scoring after closing numbers.', Icons.sports_cricket, AppColors.secondary, 'ENGLISH_CRICKET'),
      _GameMode('Around the Clock', 'Hit 1-20 in sequence, then bull. Perfect for warm-ups!', Icons.access_time, AppColors.accent, 'ATC'),
      _GameMode('Shanghai', 'Score-based. Hit single, double, AND treble in one turn to win instantly!', Icons.location_city, AppColors.warning, 'SHANGHAI'),
      _GameMode('Killer', 'Elimination game. Become killer and take out opponents.', Icons.dangerous, AppColors.error, 'KILLER'),
      _GameMode('Halve-It', 'High-stakes scoring. Miss your target and your score gets halved!', Icons.trending_down, AppColors.warning, 'HALVE_IT'),
      _GameMode('Bob\'s 27', 'Start at 27, work through doubles. Add or subtract on hit/miss.', Icons.exposure, AppColors.primary, 'BOBS_27'),
      _GameMode('Scram', 'Two-player game. One opens numbers, one scores. Then switch!', Icons.swap_horiz, AppColors.secondary, 'SCRAM'),
      _GameMode('Tic-Tac-Toe', 'Get three in a row on the dartboard. Classic strategy game!', Icons.tag, AppColors.accent, 'TIC_TAC_TOE'),
      _GameMode('All-Fives', 'Mental math game. Score only when divisible by 5.', Icons.filter_5, AppColors.warning, 'ALL_FIVES'),
      _GameMode('Mickey Mouse', '10-round game targeting specific numbers. Consistency wins.', Icons.mouse, AppColors.accent, 'MICKEY_MOUSE'),
      _GameMode('Gotcha', 'Land exactly on opponent\'s score to send them back. Chaos ensues!', Icons.gps_fixed, AppColors.error, 'GOTCHA'),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.darkGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('Choose Game Mode', style: AppTextStyles.headlineMedium),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: modes.length,
                  itemBuilder: (context, index) => _GameModeCard(mode: modes[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameMode {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String key;

  _GameMode(this.title, this.description, this.icon, this.color, this.key);
}

class _GameModeCard extends StatelessWidget {
  final _GameMode mode;

  const _GameModeCard({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      height: 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  mode.color.withOpacity(0.2),
                  AppColors.bgCard.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              border: Border.all(color: mode.color.withOpacity(0.4), width: 2),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/game-setup/${mode.key}'),
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [mode.color, mode.color.withOpacity(0.6)]),
                          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                          boxShadow: [
                            BoxShadow(
                              color: mode.color.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(mode.icon, size: 40, color: AppColors.bgDark),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(mode.title, style: AppTextStyles.headlineMedium),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              mode.description,
                              style: AppTextStyles.bodyMedium,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: mode.color, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
