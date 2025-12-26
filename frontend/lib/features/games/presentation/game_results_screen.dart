import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/widgets/dartboard_icon.dart';

class GameResultsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> gameResult;
  
  const GameResultsScreen({
    required this.gameResult,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<GameResultsScreen> createState() => _GameResultsScreenState();
}

class _GameResultsScreenState extends ConsumerState<GameResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameType = widget.gameResult['game_type'] as String? ?? 'Unknown';
    final playersResults =
        widget.gameResult['players_results'] as List<dynamic>? ?? [];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.primaryGradient,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header with game type
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        const DartboardIcon(size: 64, color: Colors.white),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Game Complete!',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: Colors.white,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          gameType,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Players Results
                  if (playersResults.isNotEmpty)
                    Column(
                      children: [
                        Text(
                          'Final Standings',
                          style: AppTextStyles.titleLarge
                              .copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...List.generate(
                          playersResults.length,
                          (index) => _PlayerResultCard(
                            playerData: playersResults[index],
                            position: index + 1,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.xl),

                  // Comprehensive Statistics Section
                  if (playersResults.isNotEmpty &&
                      (playersResults[0]['is_current_user'] == true ||
                          playersResults.any((p) => p['is_current_user'] == true)))
                    Column(
                      children: [
                        Text(
                          'Your Game Statistics',
                          style: AppTextStyles.titleLarge
                              .copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...List.generate(
                          playersResults.length,
                          (index) {
                            final player = playersResults[index];
                            if (player['is_current_user'] == true) {
                              return _ComprehensiveStatsCard(
                                playerData: player,
                              );
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.xl),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.home),
                          label: const Text('Home'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to stats screen
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.bar_chart),
                          label: const Text('View Stats'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerResultCard extends StatelessWidget {
  final Map<String, dynamic> playerData;
  final int position;

  const _PlayerResultCard({
    required this.playerData,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final isWinner = playerData['is_winner'] as bool? ?? false;
    final playerName = playerData['name'] as String? ?? 'Unknown';
    final finalScore = playerData['final_score'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isWinner ? Colors.amber[700] : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: isWinner ? Colors.amber : Colors.white24,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Position Badge
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isWinner ? Colors.amber : AppColors.primary,
            ),
            child: Center(
              child: Text(
                position.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Player Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isWinner)
                  Row(
                    children: [
                      Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      const Text(
                        'Winner',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                finalScore.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Points',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComprehensiveStatsCard extends StatelessWidget {
  final Map<String, dynamic> playerData;

  const _ComprehensiveStatsCard({
    required this.playerData,
  });

  @override
  Widget build(BuildContext context) {
    final averagePerDart = (playerData['average_per_dart'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final averagePerRound = (playerData['average_per_round'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final totalThrows = playerData['total_throws'] as int? ?? 0;
    final count180s = playerData['count_180s'] as int? ?? 0;
    final count140Plus = playerData['count_140_plus'] as int? ?? 0;
    final count100Plus = playerData['count_100_plus'] as int? ?? 0;
    final highestScore = playerData['highest_score'] as int? ?? 0;
    final checkoutPercentage = (playerData['checkout_percentage'] as num?)?.toStringAsFixed(1) ?? '0.0';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          // Primary Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCard(
                label: 'Avg/Dart',
                value: averagePerDart,
                icon: Icons.target,
              ),
              _StatCard(
                label: 'Avg/Round',
                value: averagePerRound,
                icon: Icons.trending_up,
              ),
              _StatCard(
                label: 'Total Darts',
                value: totalThrows.toString(),
                icon: Icons.format_list_numbered,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // High Score Segments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCard(
                label: '180s',
                value: count180s.toString(),
                icon: Icons.star,
                color: Colors.amber,
              ),
              _StatCard(
                label: '140+',
                value: count140Plus.toString(),
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
              _StatCard(
                label: '100+',
                value: count100Plus.toString(),
                icon: Icons.show_chart,
                color: Colors.deepOrange,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Additional Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCard(
                label: 'High Score',
                value: highestScore.toString(),
                icon: Icons.emoji_events,
                color: Colors.yellow,
              ),
              _StatCard(
                label: 'Checkout %',
                value: '$checkoutPercentage%',
                icon: Icons.check_circle,
                color: Colors.greenAccent,
              ),
            ],
          ),

          // Summary Text
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: Column(
              children: [
                const Text(
                  'Game Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'You threw $totalThrows darts with an average of $averagePerDart points per dart',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'You hit $count180s 180s and $count140Plus scores of 140 or more',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color = Colors.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
