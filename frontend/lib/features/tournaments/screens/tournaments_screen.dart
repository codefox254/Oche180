import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tournament.dart';
import '../services/tournament_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import 'tournament_detail_screen.dart';
import 'create_tournament_screen.dart';

class TournamentsScreen extends ConsumerStatefulWidget {
  const TournamentsScreen({super.key});

  @override
  ConsumerState<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends ConsumerState<TournamentsScreen> {

  List<Tournament> _upcomingTournaments = [];
  List<Tournament> _ongoingTournaments = [];
  List<Tournament> _completedTournaments = [];
  List<Tournament> _myTournaments = [];

  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  String? _error;
  bool _onlyMine = false;
  Set<int> _myTournamentIds = {};

  @override
  void initState() {
    super.initState();
    // Single initial load only
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authProvider);
      final service = TournamentService(ApiService(authToken: auth.token));

      final upcoming = await service.getUpcomingTournaments();
      final ongoing = await service.getTournaments(status: 'in_progress');
      final completed = await service.getTournaments(status: 'completed');
      final mine = auth.isAuthenticated ? await service.getMyTournaments() : <Tournament>[];

      if (!mounted) return;

      setState(() {
        _upcomingTournaments = upcoming;
        _ongoingTournaments = ongoing;
        _completedTournaments = completed;
        _myTournaments = mine;
        _myTournamentIds = mine.map((t) => t.id).toSet();
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Set empty lists instead of showing error
        _upcomingTournaments = [];
        _ongoingTournaments = [];
        _completedTournaments = [];
        _myTournaments = [];
        _myTournamentIds = {};
        _error = null; // Don't show error message
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    }
  }

  List<Tournament> _visible(List<Tournament> list) {
    if (!_onlyMine) return list;
    return list.where((t) => _myTournamentIds.contains(t.id)).toList();
  }

  Future<void> _openCreateTournament() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateTournamentScreen(),
      ),
    );
    // Reload after creating a tournament
    _loadTournaments();
  }

  bool get _hasAnyTournaments {
    return _upcomingTournaments.isNotEmpty ||
           _ongoingTournaments.isNotEmpty ||
           _completedTournaments.isNotEmpty;
  }

  bool get _hasLiveTournaments => _ongoingTournaments.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Tournaments'),
        actions: [
          if (_hasLiveTournaments && _hasLoadedOnce)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: const Icon(Icons.circle, size: 12, color: Colors.red),
                label: Text('${_ongoingTournaments.length} LIVE'),
                backgroundColor: Colors.red.withOpacity(0.1),
              ),
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadTournaments,
          ),
        ],
      ),
      body: _isLoading && !_hasLoadedOnce
          ? const Center(child: CircularProgressIndicator())
          : _error != null && !_hasLoadedOnce
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTournaments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : !_hasAnyTournaments && _hasLoadedOnce
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadTournaments,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _JourneyHeader(
                            onCreate: _openCreateTournament,
                            onlyMine: _onlyMine,
                            onToggleMine: (value) => setState(() => _onlyMine = value),
                            myCount: _myTournaments.length,
                          ),
                          const SizedBox(height: 12),
                          _ProgressStrip(),
                          const SizedBox(height: 20),
                          
                          // Live tournaments section - only shown when tournaments are ongoing
                          if (_hasLiveTournaments) ...[
                            _LiveSection(
                              tournaments: _visible(_ongoingTournaments),
                              onTap: (t) => _openTournament(t.id),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          if (!_hasLiveTournaments) ...[
                            _Section(
                              title: 'Ongoing',
                              subtitle: 'Tournaments in progress',
                              tournaments: _visible(_ongoingTournaments),
                              emptyLabel: _onlyMine
                                  ? 'You have no ongoing tournaments.'
                                  : 'No tournaments are currently in progress.',
                              onTap: (t) => _openTournament(t.id),
                            ),
                            const SizedBox(height: 12),
                          ],
                          
                          _Section(
                            title: 'Upcoming',
                            subtitle: 'Registration and scheduled events',
                            tournaments: _visible(_upcomingTournaments),
                            emptyLabel: _onlyMine
                                ? 'Create one to appear here.'
                                : 'Nothing scheduled yet. Create the first one.',
                            onTap: (t) => _openTournament(t.id),
                          ),
                          const SizedBox(height: 12),
                          _Section(
                            title: 'Completed',
                            subtitle: 'Past events and results',
                            tournaments: _visible(_completedTournaments),
                            emptyLabel: _onlyMine
                                ? 'You have no completed tournaments.'
                                : 'No completed tournaments to show.',
                            onTap: (t) => _openTournament(t.id),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: _openCreateTournament,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Create a new tournament'),
                          ),
                        ],
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTournament,
        icon: const Icon(Icons.add),
        label: const Text('New Tournament'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 100,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Tournaments Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first tournament to get started.\nOrganize competitions and track results.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openCreateTournament,
              icon: const Icon(Icons.add_circle_outline, size: 28),
              label: const Text('Create First Tournament'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTournament(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentDetailScreen(tournamentId: id),
      ),
    );
    // Reload tournaments list after viewing details
    _loadTournaments();
  }
}

// Live tournaments section - only shown when tournaments actually exist
class _LiveSection extends StatelessWidget {
  final List<Tournament> tournaments;
  final ValueChanged<Tournament> onTap;

  const _LiveSection({
    required this.tournaments,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tournaments.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.circle, size: 12, color: Colors.red),
              ),
              const SizedBox(width: 12),
              Text(
                'LIVE NOW',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
              ),
              const Spacer(),
              Chip(
                label: Text('${tournaments.length}'),
                backgroundColor: Colors.red.withOpacity(0.2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'These tournaments are currently in progress',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 12),
          ...tournaments.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TournamentCard(tournament: t, onTap: () => onTap(t)),
              )),
        ],
      ),
    );
  }
}

class _JourneyHeader extends StatelessWidget {
  final VoidCallback onCreate;
  final bool onlyMine;
  final ValueChanged<bool> onToggleMine;
  final int myCount;

  const _JourneyHeader({
    required this.onCreate,
    required this.onlyMine,
    required this.onToggleMine,
    required this.myCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.12),
            Theme.of(context).colorScheme.secondary.withOpacity(0.08),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Plan, run, complete. Keep your tournaments moving.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create tournament'),
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: Text('My tournaments ($myCount)'),
                selected: onlyMine,
                onSelected: onToggleMine,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step('Registration', Icons.how_to_reg),
      _Step('In play', Icons.sports_esports),
      _Step('Results', Icons.flag_circle),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _StepTile(label: steps[i].label, icon: steps[i].icon, active: true),
          if (i < steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
        ],
      ],
    );
  }
}

class _Step {
  final String label;
  final IconData icon;

  const _Step(this.label, this.icon);
}

class _StepTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;

  const _StepTile({
    required this.label,
    required this.icon,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Tournament> tournaments;
  final String emptyLabel;
  final ValueChanged<Tournament> onTap;

  const _Section({
    required this.title,
    required this.subtitle,
    required this.tournaments,
    required this.emptyLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                ),
              ],
            ),
            if (tournaments.isNotEmpty)
              Chip(
                label: Text('${tournaments.length}'),
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (tournaments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Text(emptyLabel),
          )
        else
          ...tournaments.map((t) => _TournamentCard(tournament: t, onTap: () => onTap(t))),
      ],
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;

  const _TournamentCard({
    required this.tournament,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tournament.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _StatusPill(status: tournament.status, label: tournament.statusDisplay),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tournament.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(tournament.formatDisplay),
                    avatar: const Icon(Icons.emoji_events, size: 16),
                  ),
                  Chip(
                    label: Text('${tournament.participantCount}/${tournament.maxParticipants} players'),
                    avatar: const Icon(Icons.people, size: 16),
                  ),
                  Chip(
                    label: Text(tournament.organizerName.isNotEmpty ? tournament.organizerName : 'Organizer'),
                    avatar: const Icon(Icons.person, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Timeline(
                status: tournament.status,
                startTime: tournament.startTime,
                registrationEnd: tournament.registrationEnd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final String label;

  const _StatusPill({required this.status, required this.label});

  Color _color(BuildContext context) {
    switch (status) {
      case 'REG_OPEN':
        return Colors.blue;
      case 'REG_CLOSED':
        return Colors.indigo;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'PAUSED':
        return Colors.amber;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final String status;
  final DateTime startTime;
  final DateTime registrationEnd;

  const _Timeline({
    required this.status,
    required this.startTime,
    required this.registrationEnd,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step('Upcoming', Icons.schedule),
      _Step('Live', Icons.play_arrow),
      _Step('Finished', Icons.flag),
    ];

    int activeIndex = 0;
    switch (status) {
      case 'IN_PROGRESS':
        activeIndex = 1;
        break;
      case 'COMPLETED':
        activeIndex = 2;
        break;
      default:
        activeIndex = 0;
    }

    String timeLabel;
    if (status == 'COMPLETED') {
      timeLabel = 'Completed ${_formatDate(startTime)}';
    } else if (status == 'REG_CLOSED') {
      timeLabel = 'Starts ${_formatDate(startTime)}';
    } else if (status == 'REG_OPEN') {
      timeLabel = 'Registration ends ${_formatDate(registrationEnd)}';
    } else {
      timeLabel = 'Starts ${_formatDate(startTime)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              _StepTile(label: steps[i].label, icon: steps[i].icon, active: i <= activeIndex),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: i < activeIndex
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_month, size: 16),
            const SizedBox(width: 6),
            Text(timeLabel, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0) {
      return 'today at ${_pad(date.hour)}:${_pad(date.minute)}';
    } else if (diff.inDays == 1) {
      return 'tomorrow at ${_pad(date.hour)}:${_pad(date.minute)}';
    } else if (diff.inDays.abs() < 7) {
      if (diff.isNegative) {
        return '${diff.inDays.abs()}d ago';
      }
      return 'in ${diff.inDays}d';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}
