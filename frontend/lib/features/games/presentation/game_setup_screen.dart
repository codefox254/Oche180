import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_design.dart';

class GameSetupScreen extends StatefulWidget {
  final String gameMode;

  const GameSetupScreen({super.key, required this.gameMode});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  bool _isTeamMode = false;
  int _playerCount = 1; // For singles: 1-6 players
  int _teamCount = 2; // For teams: 2-4 teams
  
  // Match format options
  String _matchFormat = 'single'; // 'single', 'best_of', 'sets'
  int _bestOfLegs = 3; // Best of 3, 5, 7, etc.
  int _setsToWin = 3; // First to 3 sets
  int _legsPerSet = 3; // First to 3 legs per set
  
  final List<TextEditingController> _playerControllers = [
    TextEditingController(text: 'Player 1'),
  ];

  @override
  void dispose() {
    for (var controller in _playerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updatePlayerCount(int count) {
    setState(() {
      _playerCount = count;
      while (_playerControllers.length < count) {
        _playerControllers.add(
          TextEditingController(text: 'Player ${_playerControllers.length + 1}'),
        );
      }
      while (_playerControllers.length > count) {
        _playerControllers.removeLast().dispose();
      }
    });
  }

  void _updateTeamCount(int count) {
    setState(() {
      _teamCount = count;
      final totalPlayers = count * 2;
      while (_playerControllers.length < totalPlayers) {
        _playerControllers.add(
          TextEditingController(text: 'Player ${_playerControllers.length + 1}'),
        );
      }
      while (_playerControllers.length > totalPlayers) {
        _playerControllers.removeLast().dispose();
      }
    });
  }

  void _toggleTeamMode() {
    setState(() {
      _isTeamMode = !_isTeamMode;
      if (_isTeamMode) {
        // Switch to team mode - 2 teams by default
        _teamCount = 2;
        final totalPlayers = _teamCount * 2;
        while (_playerControllers.length < totalPlayers) {
          _playerControllers.add(
            TextEditingController(text: 'Player ${_playerControllers.length + 1}'),
          );
        }
        while (_playerControllers.length > totalPlayers) {
          _playerControllers.removeLast().dispose();
        }
      } else {
        // Switch to singles mode - 1 player by default
        _playerCount = 1;
        while (_playerControllers.length < _playerCount) {
          _playerControllers.add(
            TextEditingController(text: 'Player ${_playerControllers.length + 1}'),
          );
        }
        while (_playerControllers.length > _playerCount) {
          _playerControllers.removeLast().dispose();
        }
      }
    });
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
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Setup Game', style: AppTextStyles.headlineMedium),
                        Text(
                          widget.gameMode,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Game Mode Toggle: Singles vs Teams
                      _SectionCard(
                        title: 'Game Mode',
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _toggleTeamMode(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: !_isTeamMode ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                    border: Border.all(
                                      color: !_isTeamMode ? AppColors.primary : Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        const Icon(Icons.person, color: AppColors.primary),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text('Singles', style: AppTextStyles.labelLarge),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _toggleTeamMode(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: _isTeamMode ? AppColors.accent.withOpacity(0.2) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                    border: Border.all(
                                      color: _isTeamMode ? AppColors.accent : Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        const Icon(Icons.group, color: AppColors.accent),
                                        const SizedBox(height: AppSpacing.sm),
                                        Text('Teams (2v2)', style: AppTextStyles.labelLarge),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Match Format Section
                      if (widget.gameMode == '501')
                        _SectionCard(
                          title: 'Match Format',
                          child: Column(
                            children: [
                              // Format Type Selector
                              Row(
                                children: [
                                  Expanded(
                                    child: _FormatButton(
                                      label: 'Single Leg',
                                      isSelected: _matchFormat == 'single',
                                      onTap: () => setState(() => _matchFormat = 'single'),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: _FormatButton(
                                      label: 'Best of',
                                      isSelected: _matchFormat == 'best_of',
                                      onTap: () => setState(() => _matchFormat = 'best_of'),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: _FormatButton(
                                      label: 'Sets',
                                      isSelected: _matchFormat == 'sets',
                                      onTap: () => setState(() => _matchFormat = 'sets'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              // Best Of Configuration
                              if (_matchFormat == 'best_of') ...[
                                Text('Best of how many legs?', style: AppTextStyles.bodyLarge),
                                const SizedBox(height: AppSpacing.md),
                                Wrap(
                                  spacing: AppSpacing.md,
                                  children: [3, 5, 7, 9, 11].map((num) {
                                    return GestureDetector(
                                      onTap: () => setState(() => _bestOfLegs = num),
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: _bestOfLegs == num ? AppColors.secondary : AppColors.bgLight,
                                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                          border: Border.all(
                                            color: _bestOfLegs == num ? AppColors.secondary : Colors.transparent,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$num',
                                            style: AppTextStyles.titleLarge.copyWith(
                                              color: _bestOfLegs == num ? AppColors.bgDark : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              // Sets Configuration
                              if (_matchFormat == 'sets') ...[
                                Text('First to how many sets?', style: AppTextStyles.bodyLarge),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [2, 3, 4, 5].map((num) {
                                    return GestureDetector(
                                      onTap: () => setState(() => _setsToWin = num),
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: _setsToWin == num ? AppColors.accent : AppColors.bgLight,
                                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$num',
                                            style: AppTextStyles.titleLarge.copyWith(
                                              color: _setsToWin == num ? Colors.white : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text('Legs per set (First to...)', style: AppTextStyles.bodyLarge),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [2, 3, 4, 5].map((num) {
                                    return GestureDetector(
                                      onTap: () => setState(() => _legsPerSet = num),
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: _legsPerSet == num ? AppColors.primary : AppColors.bgLight,
                                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$num',
                                            style: AppTextStyles.titleLarge.copyWith(
                                              color: _legsPerSet == num ? AppColors.bgDark : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl),
                      // Player Count Selection
                      if (!_isTeamMode)
                        _SectionCard(
                          title: 'Number of Players (1-6)',
                          child: Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.md,
                            children: List.generate(6, (index) {
                              final count = index + 1;
                              final isSelected = _playerCount == count;
                              return GestureDetector(
                                onTap: () => _updatePlayerCount(count),
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(colors: AppColors.primaryGradient)
                                        : null,
                                    color: isSelected ? null : AppColors.bgLight,
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$count',
                                      style: AppTextStyles.headlineMedium.copyWith(
                                        color: isSelected ? AppColors.bgDark : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      // Team Count Selection
                      if (_isTeamMode)
                        _SectionCard(
                          title: 'Number of Teams (2-4)',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [2, 3, 4].map((count) {
                              final isSelected = _teamCount == count;
                              return GestureDetector(
                                onTap: () => _updateTeamCount(count),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(colors: AppColors.accentGradient)
                                        : null,
                                    color: isSelected ? null : AppColors.bgLight,
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                    border: Border.all(
                                      color: isSelected ? AppColors.accent : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$count',
                                      style: AppTextStyles.headlineMedium.copyWith(
                                        color: isSelected ? AppColors.bgDark : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl),
                      // Player Names
                      _SectionCard(
                        title: _isTeamMode
                            ? 'Players by Team'
                            : 'Player Names',
                        child: _isTeamMode
                            ? _TeamPlayersList(
                                teamCount: _teamCount,
                                playerControllers: _playerControllers,
                              )
                            : Column(
                                children: List.generate(_playerCount, (index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                    child: TextFormField(
                                      controller: _playerControllers[index],
                                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
                                      decoration: InputDecoration(
                                        labelText: 'Player ${index + 1}',
                                        prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Get player names
                      final playerNames = _playerControllers
                          .take(_isTeamMode ? _teamCount * 2 : _playerCount)
                          .map((c) => c.text)
                          .toList();
                      
                      // Navigate to bull-to-start screen with players and match config
                      context.push(
                        '/bull-start',
                        extra: {
                          'gameMode': widget.gameMode,
                          'players': playerNames,
                          'matchConfig': {
                            'isTeamMode': _isTeamMode,
                            'teamCount': _teamCount,
                            'matchFormat': _matchFormat,
                            'bestOfLegs': _bestOfLegs,
                            'setsToWin': _setsToWin,
                            'legsPerSet': _legsPerSet,
                          },
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    ),
                    child: const Text('Start Game'),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppBorderRadius.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.bgCard.withOpacity(0.6),
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamPlayersList extends StatelessWidget {
  final int teamCount;
  final List<TextEditingController> playerControllers;

  const _TeamPlayersList({
    required this.teamCount,
    required this.playerControllers,
  });

  @override
  Widget build(BuildContext context) {
    final teamColors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.secondary,
      AppColors.error,
    ];

    return Column(
      children: List.generate(teamCount, (teamIndex) {
        final teamColor = teamColors[teamIndex % teamColors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: teamColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(color: teamColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team ${teamIndex + 1}',
                  style: AppTextStyles.titleLarge.copyWith(color: teamColor),
                ),
                const SizedBox(height: AppSpacing.md),
                ...List.generate(2, (playerIndex) {
                  final globalIndex = teamIndex * 2 + playerIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: TextFormField(
                      controller: playerControllers[globalIndex],
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Player ${globalIndex + 1}',
                        prefixIcon: Icon(Icons.person, color: teamColor),
                        prefixIconColor: teamColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          borderSide: BorderSide(color: teamColor.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          borderSide: BorderSide(color: teamColor),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _FormatButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.secondary : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: isSelected ? AppColors.secondary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
