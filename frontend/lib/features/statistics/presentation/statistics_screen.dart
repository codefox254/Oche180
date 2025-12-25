import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_design.dart';
import '../data/statistics_api.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsApi _api = StatisticsApi(baseUrl: 'http://127.0.0.1:8000/api');
  
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _personalBests = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      final stats = await _api.fetchStatsSummary();
      final pbs = await _api.fetchPersonalBests();
      
      setState(() {
        _stats = stats;
        _personalBests = pbs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load statistics: $e';
        _loading = false;
      });
    }
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Statistics', style: AppTextStyles.headlineMedium),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.primary),
                      onPressed: _loadStats,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                                const SizedBox(height: AppSpacing.md),
                                Text(_error!, style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
                                const SizedBox(height: AppSpacing.lg),
                                ElevatedButton(
                                  onPressed: _loadStats,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            children: [
                              _buildOverviewSection(),
                              const SizedBox(height: AppSpacing.lg),
                              _buildAveragesSection(),
                              const SizedBox(height: AppSpacing.lg),
                              _buildHighlightsSection(),
                              const SizedBox(height: AppSpacing.lg),
                              _buildModeBreakdownSection(),
                              const SizedBox(height: AppSpacing.lg),
                              _buildRecentFormSection(),
                              const SizedBox(height: AppSpacing.lg),
                              _buildPersonalBestsSection(),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Games',
                value: '${_stats?['total_games'] ?? 0}',
                icon: Icons.sports_esports,
              ),
              _StatItem(
                label: 'Wins',
                value: '${_stats?['total_wins'] ?? 0}',
                icon: Icons.emoji_events,
                color: AppColors.success,
              ),
              _StatItem(
                label: 'Win %',
                value: '${_stats?['win_percentage'] ?? 0}%',
                icon: Icons.trending_up,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAveragesSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Averages', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Overall Avg',
                value: '${_stats?['overall_average'] ?? 0.0}',
                icon: Icons.show_chart,
              ),
              _StatItem(
                label: 'Best Game Avg',
                value: '${_stats?['best_game_average'] ?? 0.0}',
                icon: Icons.star,
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Highlights', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: '180s',
                value: '${_stats?['total_180s'] ?? 0}',
                icon: Icons.whatshot,
                color: AppColors.error,
              ),
              _StatItem(
                label: '140+',
                value: '${_stats?['total_140_plus'] ?? 0}',
                icon: Icons.local_fire_department,
                color: AppColors.warning,
              ),
              _StatItem(
                label: '100+',
                value: '${_stats?['total_100_plus'] ?? 0}',
                icon: Icons.flash_on,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeBreakdownSection() {
    final modeStats = _stats?['stats_by_mode'] as Map<String, dynamic>? ?? {};
    if (modeStats.isEmpty) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Games by Mode', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          ...modeStats.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: AppTextStyles.bodyLarge),
                  Text('${entry.value} games', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentFormSection() {
    final recentForm = _stats?['recent_form'] as List<dynamic>? ?? [];
    if (recentForm.isEmpty) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Form (Last 10)', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          ...recentForm.map((game) {
            final result = game['result'] as String;
            final isWin = result == 'W';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isWin ? AppColors.success : AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        result,
                        style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(game['game_type'] ?? 'Unknown', style: AppTextStyles.bodyLarge),
                        if (game['average_per_dart'] != null)
                          Text(
                            'Avg: ${game['average_per_dart']}',
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  if (game['highest_score'] != null)
                    Text(
                      'High: ${game['highest_score']}',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPersonalBestsSection() {
    if (_personalBests.isEmpty) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal Bests', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          ..._personalBests.map((pb) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.military_tech, color: AppColors.warning, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pb['category'] ?? 'Achievement', style: AppTextStyles.bodyLarge),
                        Text(
                          pb['description'] ?? '',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${pb['value'] ?? ''}',
                    style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.bgCard.withOpacity(0.6),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(color: AppColors.bgLight.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppColors.primary, size: 32),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.titleLarge.copyWith(color: color ?? AppColors.textPrimary),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
