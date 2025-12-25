import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_design.dart';

class BullToStartScreen extends StatefulWidget {
  final List<String> players;
  final String gameMode;
  final Map<String, dynamic>? matchConfig;

  const BullToStartScreen({
    super.key,
    required this.players,
    required this.gameMode,
    this.matchConfig,
  });

  @override
  State<BullToStartScreen> createState() => _BullToStartScreenState();
}

class _BullToStartScreenState extends State<BullToStartScreen> {
  int? _winner;
  final Map<String, int> _bullScores = {};

  void _selectWinner(int index) {
    setState(() {
      _winner = index;
    });
  }

  void _startGame() {
    if (_winner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select who won the bull'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final matchConfig = widget.matchConfig ?? {};
    
    context.push(
      '/game-scoring/${widget.gameMode}',
      extra: {
        'players': widget.players,
        'isTeamMode': matchConfig['isTeamMode'] ?? false,
        'teamCount': matchConfig['teamCount'],
        'matchFormat': matchConfig['matchFormat'],
        'bestOfLegs': matchConfig['bestOfLegs'],
        'setsToWin': matchConfig['setsToWin'],
        'legsPerSet': matchConfig['legsPerSet'],
        'bullWinner': _winner,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bull to Start', style: AppTextStyles.headlineMedium),
                          Text(
                            'Who throws closest to the bullseye?',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Instructions
              Container(
                margin: const EdgeInsets.all(AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Each player throws one dart at the bullseye. Closest to the center throws first.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Player Selection
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: widget.players.length,
                  itemBuilder: (context, index) {
                    final isWinner = _winner == index;
                    return GestureDetector(
                      onTap: () => _selectWinner(index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          gradient: isWinner
                              ? const LinearGradient(
                                  colors: AppColors.primaryGradient,
                                )
                              : null,
                          color: isWinner ? null : AppColors.bgCard.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                          border: Border.all(
                            color: isWinner
                                ? AppColors.primary
                                : AppColors.bgLight.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: isWinner
                                    ? Colors.white.withOpacity(0.2)
                                    : AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(AppBorderRadius.full),
                              ),
                              child: Icon(
                                Icons.person,
                                color: isWinner ? Colors.white : AppColors.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.players[index],
                                    style: AppTextStyles.titleLarge.copyWith(
                                      color: isWinner
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    isWinner ? 'Closest to bull' : 'Tap to select',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: isWinner
                                          ? Colors.white.withOpacity(0.8)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isWinner)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 32,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Start Button
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      backgroundColor: AppColors.primary,
                    ),
                    child: Text(
                      _winner != null
                          ? 'Start Game - ${widget.players[_winner!]} throws first'
                          : 'Select Winner to Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
