import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../services/tournament_service.dart';
import '../../../core/services/api_service.dart';

class ManageEntriesScreen extends StatefulWidget {
  final int tournamentId;

  const ManageEntriesScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  State<ManageEntriesScreen> createState() => _ManageEntriesScreenState();
}

class _ManageEntriesScreenState extends State<ManageEntriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TournamentService _tournamentService;
  
  List<TournamentEntry> _allEntries = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tournamentService = TournamentService(ApiService());
    _loadEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entries = await _tournamentService.getTournamentEntries(widget.tournamentId);
      setState(() {
        _allEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<TournamentEntry> _filterEntries(String status) {
    return _allEntries.where((e) => e.status == status).toList();
  }

  Future<void> _approveEntry(TournamentEntry entry) async {
    try {
      await _tournamentService.approveEntry(widget.tournamentId, entry.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry approved')),
        );
        _loadEntries();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showAddPlayersDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddPlayersDialog(
        tournamentId: widget.tournamentId,
        tournamentService: _tournamentService,
        onPlayersAdded: _loadEntries,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Entries'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'All (${_allEntries.length})'),
            Tab(text: 'Pending (${_filterEntries('pending').length})'),
            Tab(text: 'Approved (${_filterEntries('approved').length})'),
            Tab(text: 'Rejected (${_filterEntries('rejected').length})'),
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
                        onPressed: _loadEntries,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEntriesList(_allEntries),
                    _buildEntriesList(_filterEntries('pending')),
                    _buildEntriesList(_filterEntries('approved')),
                    _buildEntriesList(_filterEntries('rejected')),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPlayersDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Players'),
      ),
    );
  }

  Widget _buildEntriesList(List<TournamentEntry> entries) {
    if (entries.isEmpty) {
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
              'No entries found',
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
      onRefresh: _loadEntries,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          return _EntryCard(
            entry: entries[index],
            onApprove: () => _approveEntry(entries[index]),
          );
        },
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final TournamentEntry entry;
  final VoidCallback onApprove;

  const _EntryCard({
    required this.entry,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(entry.playerName[0].toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.playerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Registered: ${_formatDate(entry.registeredAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(entry),
              ],
            ),
            
            if (entry.seedNumber != null) ...[
              const SizedBox(height: 8),
              Text(
                'Seed Number: ${entry.seedNumber}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
            
            if (entry.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Reject entry
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onApprove,
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TournamentEntry entry) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _AddPlayersDialog extends StatefulWidget {
  final int tournamentId;
  final TournamentService tournamentService;
  final VoidCallback onPlayersAdded;

  const _AddPlayersDialog({
    required this.tournamentId,
    required this.tournamentService,
    required this.onPlayersAdded,
  });

  @override
  State<_AddPlayersDialog> createState() => _AddPlayersDialogState();
}

class _AddPlayersDialogState extends State<_AddPlayersDialog> {
  final _playerIdsController = TextEditingController();
  bool _isSubmitting = false;
  bool _isBatchMode = true;

  @override
  void dispose() {
    _playerIdsController.dispose();
    super.dispose();
  }

  Future<void> _addPlayers() async {
    final input = _playerIdsController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter player IDs')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final playerIds = input
          .split(',')
          .map((id) => int.tryParse(id.trim()))
          .where((id) => id != null)
          .cast<int>()
          .toList();

      if (playerIds.isEmpty) {
        throw Exception('Invalid player IDs');
      }

      await widget.tournamentService.addPlayersBatch(
        widget.tournamentId,
        playerIds,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onPlayersAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${playerIds.length} player(s)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Players'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text('Batch Mode'),
            subtitle: const Text('Add multiple players at once'),
            value: _isBatchMode,
            onChanged: (value) {
              setState(() {
                _isBatchMode = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          
          const SizedBox(height: 16),
          
          if (_isBatchMode)
            TextField(
              controller: _playerIdsController,
              decoration: const InputDecoration(
                labelText: 'Player IDs (comma-separated)',
                hintText: '1, 2, 3, 4, 5',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            )
          else
            TextField(
              controller: _playerIdsController,
              decoration: const InputDecoration(
                labelText: 'Player ID',
                hintText: '123',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          
          const SizedBox(height: 8),
          
          Text(
            _isBatchMode
                ? 'Enter player IDs separated by commas'
                : 'Enter a single player ID',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _addPlayers,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}
