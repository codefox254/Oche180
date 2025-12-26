import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../services/tournament_service.dart';

class CreateTournamentScreen extends ConsumerStatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  ConsumerState<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends ConsumerState<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TournamentService _tournamentService;
  
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedFormat = 'single_elimination';
  int _maxParticipants = 8;
  bool _requireApproval = false;
  bool _isFeatured = false;
  DateTime? _startTime;

  // Registration window offsets relative to start time
  final Duration _registrationLead = const Duration(days: 1);
  final Duration _registrationCloseBeforeStart = const Duration(hours: 1);
  
  String? _minSkillLevel;
  String? _maxSkillLevel;
  
  bool _isSubmitting = false;

  final Map<String, String> _formatLabels = {
    'single_elimination': 'Single Elimination',
    'double_elimination': 'Double Elimination',
    'round_robin': 'Round Robin',
    'swiss': 'Swiss System',
    'groups_knockout': 'Groups + Knockout',
    'ladder': 'Ladder',
    'free_for_all': 'Free for All',
  };

  final Map<String, String> _formatDescriptions = {
    'single_elimination': 'Traditional knockout bracket. Lose once and you\'re out.',
    'double_elimination': 'Players get a second chance via a losers bracket.',
    'round_robin': 'Everyone plays everyone. Best overall record wins.',
    'swiss': 'Pair players with similar records each round.',
    'groups_knockout': 'Group stage followed by knockout playoffs.',
    'ladder': 'Challenge players ranked above you to climb the ladder.',
    'free_for_all': 'Multiplayer matches with points-based scoring.',
  };

  final List<String> _skillLevels = [
    'beginner',
    'intermediate',
    'advanced',
    'expert',
    'master',
  ];

  final Map<String, String> _skillLevelLabels = {
    'beginner': 'Beginner',
    'intermediate': 'Intermediate',
    'advanced': 'Advanced',
    'expert': 'Expert',
    'master': 'Master',
  };

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _tournamentService = TournamentService(
      ApiService(authToken: auth.token),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _startTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _createTournament() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated || auth.token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to create a tournament.')),
        );
        context.push('/auth/login');
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final now = DateTime.now();
      final start = _startTime ?? now.add(const Duration(days: 2));
      final registrationStart = start.subtract(_registrationLead);
      final registrationEnd = start.subtract(_registrationCloseBeforeStart);

      // Map UI format/skill values to backend enums
      final formatMap = {
        'single_elimination': 'SINGLE_ELIM',
        'double_elimination': 'DOUBLE_ELIM',
        'round_robin': 'ROUND_ROBIN',
        'swiss': 'SWISS',
        'groups_knockout': 'GROUPS_KO',
        'ladder': 'LADDER',
        'free_for_all': 'FFA',
      };

      String? mapSkill(String? skill) {
        if (skill == null) return null;
        switch (skill) {
          case 'beginner':
            return 'BEGINNER';
          case 'intermediate':
            return 'INTERMEDIATE';
          case 'advanced':
            return 'ADVANCED';
          case 'expert':
          case 'master':
            return 'PROFESSIONAL';
          default:
            return null;
        }
      }

      final data = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'tournament_format': formatMap[_selectedFormat] ?? 'SINGLE_ELIM',
        'game_mode': '501',
        'game_settings': {},
        'max_participants': _maxParticipants,
        'min_participants': 4,
        'allow_public_registration': true,
        'require_approval': _requireApproval,
        'is_featured': _isFeatured,
        'registration_start': registrationStart.toIso8601String(),
        'registration_end': registrationEnd.toIso8601String(),
        'start_time': start.toIso8601String(),
        'estimated_duration_hours': 2,
        'prize_pool': '0',
        'prize_description': '',
        'winner_xp_reward': 500,
        if (_minSkillLevel != null) 'min_skill_level': mapSkill(_minSkillLevel),
      };

      await _tournamentService.createTournament(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournament created successfully!')),
        );
        Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tournament'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tournament Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.emoji_events),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a tournament name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Format Selection
            Text(
              'Tournament Format',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            ..._formatLabels.entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<String>(
                  value: entry.key,
                  groupValue: _selectedFormat,
                  onChanged: (value) {
                    setState(() {
                      _selectedFormat = value!;
                    });
                  },
                  title: Text(entry.value),
                  subtitle: Text(
                    _formatDescriptions[entry.key] ?? '',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              );
            }).toList(),
            
            const SizedBox(height: 24),
            
            // Max Participants
            Text(
              'Maximum Participants: $_maxParticipants',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _maxParticipants.toDouble(),
              min: 4,
              max: 128,
              divisions: 31,
              label: _maxParticipants.toString(),
              onChanged: (value) {
                setState(() {
                  _maxParticipants = value.toInt();
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Start Time
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Start Time'),
              subtitle: Text(
                _startTime != null
                    ? '${_startTime!.day}/${_startTime!.month}/${_startTime!.year} ${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                    : 'Not set',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectStartTime,
            ),
            
            const Divider(),
            
            const SizedBox(height: 16),
            
            // Skill Level Restrictions
            Text(
              'Skill Level Restrictions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _minSkillLevel,
                    decoration: const InputDecoration(
                      labelText: 'Minimum',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('None'),
                      ),
                      ..._skillLevels.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text(_skillLevelLabels[level] ?? level),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _minSkillLevel = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _maxSkillLevel,
                    decoration: const InputDecoration(
                      labelText: 'Maximum',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('None'),
                      ),
                      ..._skillLevels.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text(_skillLevelLabels[level] ?? level),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _maxSkillLevel = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Options
            SwitchListTile(
              title: const Text('Require Approval'),
              subtitle: const Text('Manually approve each registration'),
              value: _requireApproval,
              onChanged: (value) {
                setState(() {
                  _requireApproval = value;
                });
              },
            ),
            
            SwitchListTile(
              title: const Text('Featured Tournament'),
              subtitle: const Text('Show on featured tournaments list'),
              value: _isFeatured,
              onChanged: (value) {
                setState(() {
                  _isFeatured = value;
                });
              },
            ),
            
            const SizedBox(height: 32),
            
            // Create Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _createTournament,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Tournament'),
            ),
          ],
        ),
      ),
    );
  }
}
