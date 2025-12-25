import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../services/tournament_service.dart';
import '../../../core/services/api_service.dart';

class ScoreSubmissionScreen extends StatefulWidget {
  final int matchId;
  final int tournamentId;

  const ScoreSubmissionScreen({
    super.key,
    required this.matchId,
    required this.tournamentId,
  });

  @override
  State<ScoreSubmissionScreen> createState() => _ScoreSubmissionScreenState();
}

class _ScoreSubmissionScreenState extends State<ScoreSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TournamentService _tournamentService;
  
  final _passcodeController = TextEditingController();
  final _player1ScoreController = TextEditingController();
  final _player2ScoreController = TextEditingController();
  final _notesController = TextEditingController();
  
  TournamentMatch? _match;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  bool _passcodeVerified = false;

  @override
  void initState() {
    super.initState();
    _tournamentService = TournamentService(ApiService());
    _loadMatchDetails();
  }

  @override
  void dispose() {
    _passcodeController.dispose();
    _player1ScoreController.dispose();
    _player2ScoreController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadMatchDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final matches = await _tournamentService.getTournamentMatches(widget.tournamentId);
      final match = matches.firstWhere((m) => m.id == widget.matchId);
      
      setState(() {
        _match = match;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyPasscode() async {
    if (_passcodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a passcode')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isValid = await _tournamentService.verifyPasscode(
        widget.tournamentId,
        _passcodeController.text,
      );

      setState(() {
        _passcodeVerified = isValid;
        _isLoading = false;
      });

      if (!isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid passcode')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _submitScore() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _tournamentService.submitScore(
        tournamentId: widget.tournamentId,
        matchId: widget.matchId,
        player1Score: int.parse(_player1ScoreController.text),
        player2Score: int.parse(_player2ScoreController.text),
        passcode: _passcodeController.text,
        notes: _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Score submitted successfully!')),
        );
        Navigator.pop(context, true);
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
        title: const Text('Submit Match Score'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || _match == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error ?? 'Match not found'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMatchDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Match Info
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Match Details',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          _match!.player1Name ?? 'Player 1',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'VS',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          _match!.player2Name ?? 'Player 2',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Passcode Section
                      if (!_passcodeVerified) ...[
                        Text(
                          'Enter Tournament Passcode',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _passcodeController,
                                decoration: const InputDecoration(
                                  labelText: 'Passcode',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.lock),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter passcode';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _verifyPasscode,
                              child: const Text('Verify'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Get the passcode from the tournament organizer',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ] else ...[
                        // Score Input Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text('Passcode verified'),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          'Enter Scores',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _match!.player1Name ?? 'Player 1',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _player1ScoreController,
                                    decoration: const InputDecoration(
                                      labelText: 'Score',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Invalid';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              '-',
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _match!.player2Name ?? 'Player 2',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _player2ScoreController,
                                    decoration: const InputDecoration(
                                      labelText: 'Score',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Invalid';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes (optional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitScore,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Submit Score'),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
