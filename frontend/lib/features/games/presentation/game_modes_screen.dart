import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_design.dart';

class GameModesScreen extends StatelessWidget {
  const GameModesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modes = [
      _GameMode('501', 'Start at 501, race to zero. Checkout with a double!', Icons.filter_1, AppColors.primary, '501'),
      _GameMode('Cricket', 'Close numbers 15-20 and Bull. Strategy meets skill.', Icons.grid_on, AppColors.secondary, 'CRICKET'),
      _GameMode('Around the Clock', 'Hit 1-20 in sequence, then bull to win!', Icons.access_time, AppColors.accent, 'ATC'),
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
