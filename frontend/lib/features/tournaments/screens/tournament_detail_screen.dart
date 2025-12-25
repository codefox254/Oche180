import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../services/tournament_service.dart';
import '../../../core/services/api_service.dart';
import '../widgets/tournament_bracket.dart';
import 'manage_entries_screen.dart';

class TournamentDetailScreen extends StatefulWidget {
  final int tournamentId;

  const TournamentDetailScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TournamentService _tournamentService;
  
  Tournament? _tournament;
  List<TournamentEntry> _entries = [];
  List<TournamentRound> _rounds = [];
  
  bool _isLoading = false;
  String? _error;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tournamentService = TournamentService(ApiService());
    _loadTournament();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTournament() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tournament = await _tournamentService.getTournament(widget.tournamentId);
      final entries = await _tournamentService.getTournamentEntries(widget.tournamentId);
      final rounds = await _tournamentService.getTournamentRounds(widget.tournamentId);

      setState(() {
        _tournament = tournament;
        _entries = entries;
        _rounds = rounds;
        _isLoading = false;
        // TODO: Check if current user is registered
        _isRegistered = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _registerForTournament() async {
    if (_tournament == null) return;

    try {
      await _tournamentService.registerForTournament(_tournament!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tournament!.requireApproval
                  ? 'Registration submitted! Waiting for approval.'
                  : 'Successfully registered for tournament!',
            ),
          ),
        );
        _loadTournament();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _withdrawFromTournament() async {
    if (_tournament == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw from Tournament'),
        content: const Text('Are you sure you want to withdraw? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _tournamentService.withdrawFromTournament(_tournament!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawn from tournament')),
        );
        _loadTournament();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _startTournament() async {
    if (_tournament == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Tournament'),
        content: const Text(
          'This will generate the bracket and start the tournament. '
          'No more registrations will be accepted. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _tournamentService.startTournament(_tournament!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournament started!')),
        );
        _loadTournament();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tournament'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _tournament == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tournament'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Tournament not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTournament,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_tournament!.name),
        actions: [
          // TODO: Add organizer-only actions (edit, delete)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTournament,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Bracket'),
            Tab(text: 'Participants'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildBracketTab(),
          _buildParticipantsTab(),
        ],
      ),
      bottomNavigationBar: _buildActionBar(),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadTournament,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getStatusColor()),
            ),
            child: Row(
              children: [
                Icon(_getStatusIcon(), color: _getStatusColor()),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tournament!.statusDisplay,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                      if (_tournament!.startTime != null)
                        Text(
                          'Starts: ${_formatDateTime(_tournament!.startTime!)}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Description
          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _tournament!.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          
          const SizedBox(height: 24),
          
          // Details
          Text(
            'Details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          
          _buildDetailRow(Icons.emoji_events, 'Format', _tournament!.formatDisplay),
          _buildDetailRow(Icons.people, 'Participants',
              '${_tournament!.currentParticipants}/${_tournament!.maxParticipants}'),
          _buildDetailRow(Icons.person, 'Organizer', _tournament!.organizerName),
          if (_tournament!.gameName != null)
            _buildDetailRow(Icons.sports_esports, 'Game', _tournament!.gameName!),
          if (_tournament!.minSkillLevel != null || _tournament!.maxSkillLevel != null)
            _buildDetailRow(
              Icons.bar_chart,
              'Skill Level',
              '${_tournament!.minSkillLevel ?? 'Any'} - ${_tournament!.maxSkillLevel ?? 'Any'}',
            ),
          
          const SizedBox(height: 24),
          
          // Registration Info
          if (_tournament!.isRegistrationOpen) ...[
            Text(
              'Registration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_tournament!.requireApproval)
                      const Row(
                        children: [
                          Icon(Icons.verified_user, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('Approval required for registration'),
                          ),
                        ],
                      ),
                    if (_tournament!.canRegister)
                      Text(
                        '${_tournament!.maxParticipants - _tournament!.currentParticipants} spots remaining',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    else
                      const Text(
                        'Tournament is full',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBracketTab() {
    if (_rounds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _tournament!.status == 'registration' || _tournament!.status == 'pending'
                  ? 'Bracket will be generated when tournament starts'
                  : 'No bracket available',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return TournamentBracket(
      rounds: _rounds,
      onMatchTap: (match) {
        // TODO: Show match details
      },
    );
  }

  Widget _buildParticipantsTab() {
    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No participants yet',
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
      onRefresh: _loadTournament,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${index + 1}'),
              ),
              title: Text(entry.playerName),
              subtitle: entry.seedNumber != null
                  ? Text('Seed #${entry.seedNumber}')
                  : null,
              trailing: _buildEntryStatusBadge(entry),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryStatusBadge(TournamentEntry entry) {
    Color color;
    String text;

    switch (entry.status) {
      case 'approved':
        color = Colors.green;
        text = 'Approved';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejected';
        break;
      case 'withdrawn':
        color = Colors.grey;
        text = 'Withdrawn';
        break;
      default:
        color = Colors.grey;
        text = entry.status;
    }

    return Chip(
      label: Text(text),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
    );
  }

  Widget? _buildActionBar() {
    if (_tournament == null) return null;

    // TODO: Check if user is organizer
    final bool isOrganizer = false;

    if (isOrganizer) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManageEntriesScreen(
                        tournamentId: _tournament!.id,
                      ),
                    ),
                  ).then((_) => _loadTournament());
                },
                child: const Text('Manage Entries'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _tournament!.status == 'registration'
                    ? _startTournament
                    : null,
                child: const Text('Start Tournament'),
              ),
            ),
          ],
        ),
      );
    }

    if (!_tournament!.isRegistrationOpen) {
      return null;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: _isRegistered
          ? OutlinedButton(
              onPressed: _withdrawFromTournament,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Withdraw'),
            )
          : ElevatedButton(
              onPressed: _tournament!.canRegister ? _registerForTournament : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(
                _tournament!.canRegister
                    ? 'Register for Tournament'
                    : 'Tournament Full',
              ),
            ),
    );
  }

  Color _getStatusColor() {
    switch (_tournament!.status) {
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

  IconData _getStatusIcon() {
    switch (_tournament!.status) {
      case 'registration':
        return Icons.how_to_reg;
      case 'in_progress':
        return Icons.play_circle;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
