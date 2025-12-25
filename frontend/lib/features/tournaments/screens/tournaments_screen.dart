import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../services/tournament_service.dart';
import '../../../core/services/api_service.dart';
import 'tournament_detail_screen.dart';
import 'create_tournament_screen.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TournamentService _tournamentService;
  
  List<Tournament> _featuredTournaments = [];
  List<Tournament> _upcomingTournaments = [];
  List<Tournament> _myTournaments = [];
  
  bool _isLoading = false;
  String? _error;
  
  String? _selectedFormat;
  String? _selectedStatus;

  final List<String> _formats = [
    'single_elimination',
    'double_elimination',
    'round_robin',
    'swiss',
    'groups_knockout',
    'ladder',
    'free_for_all',
  ];

  final Map<String, String> _formatLabels = {
    'single_elimination': 'Single Elimination',
    'double_elimination': 'Double Elimination',
    'round_robin': 'Round Robin',
    'swiss': 'Swiss System',
    'groups_knockout': 'Groups + Knockout',
    'ladder': 'Ladder',
    'free_for_all': 'Free for All',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tournamentService = TournamentService(ApiService());
    _loadTournaments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final featured = await _tournamentService.getFeaturedTournaments();
      final upcoming = await _tournamentService.getUpcomingTournaments();
      final my = await _tournamentService.getMyTournaments();

      setState(() {
        _featuredTournaments = featured;
        _upcomingTournaments = upcoming;
        _myTournaments = my;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tournaments = await _tournamentService.getTournaments(
        format: _selectedFormat,
        status: _selectedStatus,
      );

      setState(() {
        _upcomingTournaments = tournaments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Tournaments',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              
              // Format filter
              Text(
                'Format',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _formats.map((format) {
                  final isSelected = _selectedFormat == format;
                  return FilterChip(
                    label: Text(_formatLabels[format] ?? format),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        setState(() {
                          _selectedFormat = selected ? format : null;
                        });
                      });
                    },
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Status filter
              Text(
                'Status',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Registration'),
                    selected: _selectedStatus == 'registration',
                    onSelected: (selected) {
                      setModalState(() {
                        setState(() {
                          _selectedStatus = selected ? 'registration' : null;
                        });
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('In Progress'),
                    selected: _selectedStatus == 'in_progress',
                    onSelected: (selected) {
                      setModalState(() {
                        setState(() {
                          _selectedStatus = selected ? 'in_progress' : null;
                        });
                      });
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          setState(() {
                            _selectedFormat = null;
                            _selectedStatus = null;
                          });
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _applyFilters();
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Featured'),
            Tab(text: 'Upcoming'),
            Tab(text: 'My Tournaments'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTournaments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTournamentList(_featuredTournaments),
                    _buildTournamentList(_upcomingTournaments),
                    _buildTournamentList(_myTournaments),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateTournamentScreen(),
            ),
          );
          _loadTournaments();
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Tournament'),
      ),
    );
  }

  Widget _buildTournamentList(List<Tournament> tournaments) {
    if (tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No tournaments found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTournaments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tournaments.length,
        itemBuilder: (context, index) {
          return _TournamentCard(
            tournament: tournaments[index],
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TournamentDetailScreen(
                    tournamentId: tournaments[index].id,
                  ),
                ),
              );
              _loadTournaments();
            },
          );
        },
      ),
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

  Color _getStatusColor() {
    switch (tournament.status) {
      case 'registration':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

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
                  if (tournament.isFeatured)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Featured',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              Text(
                tournament.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(tournament.formatDisplay),
                    avatar: const Icon(Icons.emoji_events, size: 16),
                  ),
                  Chip(
                    label: Text(tournament.statusDisplay),
                    backgroundColor: _getStatusColor(),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  if (tournament.gameName != null)
                    Chip(
                      label: Text(tournament.gameName!),
                      avatar: const Icon(Icons.sports_esports, size: 16),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${tournament.currentParticipants}/${tournament.maxParticipants} players',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  if (tournament.startTime != null)
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(tournament.startTime!),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Tomorrow ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
