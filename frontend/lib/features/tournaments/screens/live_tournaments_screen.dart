import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/tournament_api_service.dart';

class LiveTournamentsScreen extends ConsumerStatefulWidget {
  const LiveTournamentsScreen({super.key});

  @override
  ConsumerState<LiveTournamentsScreen> createState() => _LiveTournamentsScreenState();
}

class _LiveTournamentsScreenState extends ConsumerState<LiveTournamentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TournamentApiService _service = TournamentApiService();

  bool _loading = true;
  String? _error;
  List<dynamic> _liveMatches = [];
  List<dynamic> _upcomingTournaments = [];
  List<dynamic> _myTournaments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated || authState.token == null) {
        setState(() {
          _error = 'Please login to view tournaments';
          _loading = false;
        });
        return;
      }

      final live = await _service.getLiveMatches(authState.token!);
      final upcoming = await _service.getTournaments(authState.token!, status: 'upcoming');
      final my = await _service.getTournaments(authState.token!);

      setState(() {
        _liveMatches = live;
        _upcomingTournaments = upcoming;
        _myTournaments = my.where((t) => t['is_participant'] == true).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
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
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _error != null
                        ? _buildErrorView()
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildLiveMatchesTab(),
                              _buildUpcomingTab(),
                              _buildMyTournamentsTab(),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to create tournament screen
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Create Tournament'),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tournaments', style: AppTextStyles.headlineMedium),
              Text(
                'Live scores & standings',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.primaryGradient),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textTertiary,
        tabs: const [
          Tab(text: 'Live'),
          Tab(text: 'Upcoming'),
          Tab(text: 'My Tournaments'),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMatchesTab() {
    if (_liveMatches.isEmpty) {
      return _buildEmptyState('No live matches', Icons.sports_esports);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _liveMatches.length,
        itemBuilder: (context, index) => _buildLiveMatchCard(_liveMatches[index]),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_upcomingTournaments.isEmpty) {
      return _buildEmptyState('No upcoming tournaments', Icons.emoji_events);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _upcomingTournaments.length,
        itemBuilder: (context, index) => _buildTournamentCard(_upcomingTournaments[index]),
      ),
    );
  }

  Widget _buildMyTournamentsTab() {
    if (_myTournaments.isEmpty) {
      return _buildEmptyState('Join a tournament to get started', Icons.person_add);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _myTournaments.length,
        itemBuilder: (context, index) => _buildTournamentCard(_myTournaments[index]),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMatchCard(Map<String, dynamic> match) {
    final player1 = match['player1'] ?? {};
    final player2 = match['player2'] ?? {};
    final score1 = match['score1'] ?? 0;
    final score2 = match['score2'] ?? 0;
    final currentLeg = match['current_leg'] ?? 1;
    final totalLegs = match['total_legs'] ?? 3;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: AppColors.error.withOpacity(0.5), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          onTap: () {
            // Navigate to match details
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Leg $currentLeg/$totalLegs',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _buildMatchupRow(
                  player1['name'] ?? 'Player 1',
                  score1,
                  score1 > score2,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildMatchupRow(
                  player2['name'] ?? 'Player 2',
                  score2,
                  score2 > score1,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(color: AppColors.bgDark),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      match['tournament_name'] ?? 'Tournament',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                    Text(
                      match['format'] ?? '501',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchupRow(String playerName, int score, bool isLeading) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.bgDark,
          child: Text(
            playerName[0].toUpperCase(),
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            playerName,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: isLeading ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isLeading ? AppColors.primary.withOpacity(0.2) : AppColors.bgDark,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: isLeading ? Border.all(color: AppColors.primary, width: 2) : null,
          ),
          child: Text(
            score.toString(),
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: isLeading ? FontWeight.bold : FontWeight.normal,
              color: isLeading ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentCard(Map<String, dynamic> tournament) {
    final name = tournament['name'] ?? 'Tournament';
    final format = tournament['format'] ?? 'single_elimination';
    final participants = tournament['participants_count'] ?? 0;
    final maxParticipants = tournament['max_participants'] ?? 0;
    final startDate = tournament['start_date'] ?? '';
    final status = tournament['status'] ?? 'upcoming';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          onTap: () {
            // Navigate to tournament details
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.primaryGradient),
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                      child: const Icon(Icons.emoji_events, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AppTextStyles.titleMedium),
                          Text(
                            _formatLabel(format),
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.bgDark),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(Icons.people, '$participants/$maxParticipants'),
                    _buildInfoChip(Icons.calendar_today, _formatDate(startDate)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final Color color;
    final String label;

    switch (status) {
      case 'live':
        color = AppColors.error;
        label = 'LIVE';
        break;
      case 'upcoming':
        color = AppColors.primary;
        label = 'UPCOMING';
        break;
      case 'completed':
        color = AppColors.success;
        label = 'COMPLETED';
        break;
      default:
        color = AppColors.textTertiary;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }

  String _formatLabel(String format) {
    return format.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
