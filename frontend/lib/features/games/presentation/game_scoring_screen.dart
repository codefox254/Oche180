import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_design.dart';

class GameScoringScreen extends StatefulWidget {
  const GameScoringScreen({
    super.key,
    required this.gameMode,
    this.players,
    this.isTeamMode = false,
    this.teamCount,
    this.matchFormat = 'single',
    this.bestOfLegs,
    this.setsToWin,
    this.legsPerSet,
    this.bullWinner,
  });

  final String gameMode;
  final List<String>? players;
  final bool isTeamMode;
  final int? teamCount;
  final String matchFormat; // 'single', 'best_of', 'sets'
  final int? bestOfLegs;
  final int? setsToWin;
  final int? legsPerSet;
  final int? bullWinner; // Index of player who won the bull

  static const List<int> commonScores = [
    40, 60, 75, 80, 85, 90, 95, 100, 110, 120, 121, 125, 133, 135, 140, 170, 180,
  ];

  @override
  State<GameScoringScreen> createState() => _GameScoringScreenState();
}

class _GameScoringScreenState extends State<GameScoringScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int currentPlayerIndex = 0;
  late final List<String> players;
  late final Map<String, int> scores;
  final List<_ThrowEntry> history = [];
  int pendingScore = 0;
  
  // Match state tracking
  late int currentSet;
  late int currentLeg;
  late Map<String, int> setsWon;
  late Map<String, int> legsWon;
  late int? originalBullWinner;
  late final int startingScore;

  int _getStartingScore() {
    final mode = widget.gameMode.toLowerCase();
    if (mode.contains('301')) return 301;
    if (mode.contains('701')) return 701;
    if (mode.contains('1001')) return 1001;
    return 501; // Default to 501
  }

  @override
  void initState() {
    super.initState();
    // Get starting score based on game mode
    startingScore = _getStartingScore();
    
    // Initialize players from widget or use defaults
    if (widget.players != null && widget.players!.isNotEmpty) {
      players = widget.players!;
    } else {
      players = ['Player 1', 'Player 2'];
    }
    
    // Initialize scores map with correct starting score
    scores = {for (var p in players) p: startingScore};
        // Initialize match state
        currentSet = 1;
        currentLeg = 1;
        setsWon = {for (var p in players) p: 0};
        legsWon = {for (var p in players) p: 0};
        originalBullWinner = widget.bullWinner;
    
        // Set starting player based on bull winner or deciding leg logic
        if (widget.bullWinner != null) {
          currentPlayerIndex = widget.bullWinner!;
        }
    
        _tabController = TabController(length: 3, vsync: this);
    
        // Show game start message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showGameStartMessage();
        });
      }
  
      void _showGameStartMessage() {
        final starter = players[currentPlayerIndex];
        String message;
    
        if (widget.matchFormat == 'sets') {
          message = 'Set $currentSet - Leg $currentLeg, $starter to throw first';
        } else if (widget.matchFormat == 'best_of') {
          message = 'Leg $currentLeg, $starter to throw first';
        } else {
          message = 'Game shot! $starter starts';
        }
    
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addScore(int value) {
    setState(() {
      pendingScore = (pendingScore * 10 + value).clamp(0, 180);
    });
  }

  void _backspace() {
    setState(() {
      pendingScore = pendingScore ~/ 10;
    });
  }

  void _submitScore() {
    if (pendingScore < 0 || pendingScore > 180) return;

    final player = players[currentPlayerIndex];
    final remaining = scores[player]! - pendingScore;
    
    // Bust conditions in 501:
    // 1. Score goes below 0
    // 2. Score equals 1 (can't finish on 1)
    // 3. Remaining is 0 but didn't finish on a double (simplified for now)
    final isBust = remaining < 0 || remaining == 1;
    
    setState(() {
      history.add(
        _ThrowEntry(
          player: player,
          scored: pendingScore,
          remaining: isBust ? scores[player]! : max(0, remaining),
          isBust: isBust,
        ),
      );
      if (!isBust) {
        scores[player] = max(0, remaining);
        // Check for winner
        if (remaining == 0) {
           _handleLegWin(player);
        }
      } else {
        // Bust: show message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('BUST! $player stays at ${scores[player]}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      pendingScore = 0;
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    });
  }
    void _handleLegWin(String winner) {
      // Increment leg wins
      legsWon[winner] = (legsWon[winner] ?? 0) + 1;
    
      // Check match format
      if (widget.matchFormat == 'sets') {
        final legsRequired = ((widget.legsPerSet ?? 3) / 2).ceil();
        if (legsWon[winner]! >= legsRequired) {
          // Winner of the set
          _handleSetWin(winner);
        } else {
          // Continue to next leg
          _startNextLeg(winner);
        }
      } else if (widget.matchFormat == 'best_of') {
        final legsRequired = ((widget.bestOfLegs ?? 3) / 2).ceil();
        if (legsWon[winner]! >= legsRequired) {
          // Winner of the match
          _showMatchWinnerDialog(winner);
        } else {
          // Continue to next leg
          _startNextLeg(winner);
        }
      } else {
        // Single leg - match over
        _showMatchWinnerDialog(winner);
      }
    }
  
    void _handleSetWin(String winner) {
      setsWon[winner] = (setsWon[winner] ?? 0) + 1;
    
      // Show set win message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$winner wins Set $currentSet!'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );
    
      final setsRequired = widget.setsToWin ?? 3;
      if (setsWon[winner]! >= setsRequired) {
        // Winner of the match
        _showMatchWinnerDialog(winner);
      } else {
        // Start next set
        setState(() {
          currentSet++;
          currentLeg = 1;
          // Reset leg wins for new set
          legsWon = {for (var p in players) p: 0};
          // Reset scores with correct starting score
          scores.updateAll((key, value) => startingScore);
          history.clear();
          pendingScore = 0;
          // Bull winner starts new set
          if (originalBullWinner != null) {
            currentPlayerIndex = originalBullWinner!;
          }
        });
      
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showGameStartMessage();
        });
      }
    }
  
    void _startNextLeg(String legWinner) {
      // Show leg win message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$legWinner wins Leg $currentLeg!'),
          backgroundColor: AppColors.secondary,
          duration: const Duration(seconds: 2),
        ),
      );
    
      setState(() {
        currentLeg++;
      
        // Reset scores for new leg with correct starting score
        scores.updateAll((key, value) => startingScore);
        history.clear();
        pendingScore = 0;
      
        // Deciding leg logic
        if (widget.matchFormat == 'best_of') {
          final totalLegs = widget.bestOfLegs ?? 3;
          final decidingLeg = totalLegs;
          if (currentLeg == decidingLeg && originalBullWinner != null) {
            // Bull winner throws first in deciding leg
            currentPlayerIndex = originalBullWinner!;
          } else {
            // Leg winner throws first in next leg
            currentPlayerIndex = players.indexOf(legWinner);
          }
        } else if (widget.matchFormat == 'sets') {
          final totalLegs = widget.legsPerSet ?? 3;
          final decidingLeg = totalLegs;
          if (currentLeg == decidingLeg && originalBullWinner != null) {
            // Bull winner throws first in deciding leg
            currentPlayerIndex = originalBullWinner!;
          } else {
            // Leg winner throws first
            currentPlayerIndex = players.indexOf(legWinner);
          }
        }
      });
    
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameStartMessage();
      });
    }
  
    void _showMatchWinnerDialog(String winner) {
      // Calculate comprehensive statistics
      final stats = _calculatePlayerStatistics();
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppBorderRadius.xl),
                      topRight: Radius.circular(AppBorderRadius.xl),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events, size: 48, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        'MATCH COMPLETE',
                        style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$winner WINS!',
                        style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                
                // Statistics
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        // Match Score
                        _buildMatchScoreCard(),
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Player Statistics Table
                        _buildStatisticsTable(stats),
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Performance Indicators
                        _buildPerformanceIndicators(stats),
                      ],
                    ),
                  ),
                ),
                
                // Actions
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.pop();
                            context.pop();
                          },
                          icon: const Icon(Icons.home),
                          label: const Text('Home'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.pop();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('New Game'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    Widget _buildMatchScoreCard() {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.bgLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: players.map((p) {
            return Column(
              children: [
                Text(p, style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                if (widget.matchFormat == 'sets')
                  Text(
                    '${setsWon[p] ?? 0}',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: setsWon[p] == setsWon.values.reduce((a, b) => a > b ? a : b) ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (widget.matchFormat == 'best_of')
                  Text(
                    '${legsWon[p] ?? 0}',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: legsWon[p] == legsWon.values.reduce((a, b) => a > b ? a : b) ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Icon(
                    scores[p] == 0 ? Icons.emoji_events : Icons.close,
                    size: 32,
                    color: scores[p] == 0 ? AppColors.primary : AppColors.error,
                  ),
                const SizedBox(height: 4),
                Text(
                  widget.matchFormat == 'sets' ? 'Sets' : widget.matchFormat == 'best_of' ? 'Legs' : 'Result',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            );
          }).toList(),
        ),
      );
    }

    Map<String, Map<String, dynamic>> _calculatePlayerStatistics() {
      final Map<String, Map<String, dynamic>> stats = {};
      
      for (final player in players) {
        final playerThrows = history.where((h) => h.player == player).toList();
        final totalDarts = playerThrows.length;
        final totalScore = playerThrows.fold<int>(0, (sum, h) => sum + h.scored);
        final validThrows = playerThrows.where((h) => !h.isBust).toList();
        
        // Calculate averages
        final average = totalDarts > 0 ? (totalScore / totalDarts).toStringAsFixed(2) : '0.00';
        final first9Avg = totalDarts >= 9 
            ? (playerThrows.take(9).fold<int>(0, (sum, h) => sum + h.scored) / 9).toStringAsFixed(2)
            : '0.00';
        
        // Count high scores
        final scores100Plus = playerThrows.where((h) => h.scored >= 100 && h.scored < 140).length;
        final scores140Plus = playerThrows.where((h) => h.scored >= 140 && h.scored < 180).length;
        final scores180 = playerThrows.where((h) => h.scored == 180).length;
        final scores60Plus = playerThrows.where((h) => h.scored >= 60 && h.scored < 100).length;
        
        // Calculate highest score
        final highestScore = playerThrows.isEmpty ? 0 : playerThrows.map((h) => h.scored).reduce((a, b) => a > b ? a : b);
        
        // Checkout percentage (simplified)
        final checkoutAttempts = playerThrows.where((h) => h.remaining < startingScore && h.remaining <= 170).length;
        final checkoutsHit = playerThrows.where((h) => h.remaining == 0).length;
        final checkoutPct = checkoutAttempts > 0 ? ((checkoutsHit / checkoutAttempts) * 100).toStringAsFixed(1) : '0.0';
        
        stats[player] = {
          'totalDarts': totalDarts,
          'totalScore': totalScore,
          'average': average,
          'first9Avg': first9Avg,
          '180s': scores180,
          '140+': scores140Plus,
          '100+': scores100Plus,
          '60+': scores60Plus,
          'highestScore': highestScore,
          'checkoutPct': checkoutPct,
          'checkouts': checkoutsHit,
        };
      }
      
      return stats;
    }

    Widget _buildStatisticsTable(Map<String, Map<String, dynamic>> stats) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match Statistics',
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Table(
              border: TableBorder.symmetric(
                inside: BorderSide(color: AppColors.bgLight.withOpacity(0.3)),
              ),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                  children: [
                    _buildTableHeader('Statistic'),
                    ...players.map((p) => _buildTableHeader(p.length > 10 ? p.substring(0, 10) : p)),
                  ],
                ),
                // Average
                _buildTableRow('Average', players.map((p) => stats[p]!['average'].toString()).toList()),
                _buildTableRow('First 9 Avg', players.map((p) => stats[p]!['first9Avg'].toString()).toList()),
                _buildTableRow('Highest Score', players.map((p) => stats[p]!['highestScore'].toString()).toList()),
                _buildTableRow('180s', players.map((p) => stats[p]!['180s'].toString()).toList(), highlight: true),
                _buildTableRow('140+', players.map((p) => stats[p]!['140+'].toString()).toList()),
                _buildTableRow('100+', players.map((p) => stats[p]!['100+'].toString()).toList()),
                _buildTableRow('60+', players.map((p) => stats[p]!['60+'].toString()).toList()),
                _buildTableRow('Checkouts', players.map((p) => stats[p]!['checkouts'].toString()).toList()),
                _buildTableRow('Checkout %', players.map((p) => '${stats[p]!['checkoutPct']}%').toList()),
                _buildTableRow('Total Darts', players.map((p) => stats[p]!['totalDarts'].toString()).toList()),
              ],
            ),
          ),
        ],
      );
    }

    TableRow _buildTableRow(String label, List<String> values, {bool highlight = false}) {
      return TableRow(
        decoration: highlight ? BoxDecoration(color: AppColors.secondary.withOpacity(0.05)) : null,
        children: [
          _buildTableCell(label, isLabel: true),
          ...values.map((v) => _buildTableCell(v)),
        ],
      );
    }

    Widget _buildTableHeader(String text) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Text(
          text,
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
          textAlign: TextAlign.center,
        ),
      );
    }

    Widget _buildTableCell(String text, {bool isLabel = false}) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Text(
          text,
          style: isLabel 
              ? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)
              : AppTextStyles.bodyMedium,
          textAlign: isLabel ? TextAlign.left : TextAlign.center,
        ),
      );
    }

    Widget _buildPerformanceIndicators(Map<String, Map<String, dynamic>> stats) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance',
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...players.map((player) {
            final avg = double.parse(stats[player]!['average']);
            final color = avg >= 80 ? Colors.green : avg >= 60 ? Colors.orange : Colors.red;
            final rating = avg >= 100 ? 'Elite' : avg >= 80 ? 'Pro' : avg >= 60 ? 'Advanced' : avg >= 40 ? 'Intermediate' : 'Beginner';
            
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: color, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(player, style: AppTextStyles.titleMedium),
                        Text(
                          '$rating • ${stats[player]!['average']} avg',
                          style: AppTextStyles.bodySmall.copyWith(color: color),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Text(
                      stats[player]!['average'].toString(),
                      style: AppTextStyles.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      );
    }


  String? _getFinishRecommendation(int score) {
    // Common finish combinations in darts
    final finishes = <int, String>{
      170: 'T20, T20, Bull',
      167: 'T20, T19, Bull',
      164: 'T20, T18, Bull',
      161: 'T20, T17, Bull',
      160: 'T20, T20, D20',
      158: 'T20, T20, D19',
      157: 'T20, T19, D20',
      156: 'T20, T20, D18',
      155: 'T20, T19, D19',
      154: 'T20, T18, D20',
      153: 'T20, T19, D18',
      152: 'T20, T20, D16',
      151: 'T20, T17, D20',
      150: 'T20, T18, D18',
      149: 'T20, T19, D16',
      148: 'T20, T20, D14',
      147: 'T20, T17, D18',
      146: 'T20, T18, D16',
      145: 'T20, T19, D14',
      144: 'T20, T20, D12',
      141: 'T20, T19, D12',
      140: 'T20, T20, D10',
      139: 'T19, T14, D20',
      138: 'T20, T18, D12',
      137: 'T20, T19, D10',
      136: 'T20, T20, D8',
      135: 'Bull, Bull, D17.5', // Actually 25, 25, 25 + 60
      134: 'T20, T14, D16',
      133: 'T20, T19, D8',
      132: 'Bull, Bull, D16',
      131: 'T20, T13, D16',
      130: 'T20, T18, D8',
      129: 'T19, T16, D12',
      128: 'T18, T14, D16',
      127: 'T20, T17, D8',
      126: 'T19, T19, D6',
      125: 'T18, T13, D16',
      124: 'T20, T14, D11',
      123: 'T19, T16, D9',
      122: 'T18, T18, D7',
      121: 'T20, T11, D14',
      120: 'T20, 20, D20',
      119: 'T19, T12, D13',
      118: 'T20, 18, D20',
      117: 'T20, 17, D20',
      116: 'T20, 16, D20',
      115: 'T19, 18, D20',
      114: 'T20, 14, D20',
      113: 'T19, 16, D20',
      112: 'T20, 12, D20',
      111: 'T19, 14, D20',
      110: 'T20, 10, D20',
      109: 'T20, 9, D20',
      108: 'T20, 8, D20',
      107: 'T19, 10, D20',
      106: 'T20, 6, D20',
      105: 'T20, 5, D20',
      104: 'T20, 4, D20',
      103: 'T19, 6, D20',
      102: 'T20, 2, D20',
      101: 'T17, 10, D20',
      100: 'T20, D20',
      98: 'T20, D19',
      96: 'T20, D18',
      94: 'T18, D20',
      92: 'T20, D16',
      90: 'T18, D18',
      88: 'T16, D20',
      86: 'T18, D16',
      84: 'T20, D12',
      82: 'Bull, D16',
      80: 'T20, D10',
      78: 'T18, D12',
      76: 'T20, D8',
      74: 'T14, D16',
      72: 'T16, D12',
      70: 'T18, D8',
      68: 'T20, D4',
      66: 'T10, D18',
      64: 'T16, D8',
      62: 'T10, D16',
      60: 'S20, D20',
      58: 'S18, D20',
      56: 'T16, D4',
      54: 'S14, D20',
      52: 'S12, D20',
      50: 'S10, D20 or Bull',
      48: 'S16, D16',
      46: 'S6, D20',
      44: 'S4, D20',
      42: 'S10, D16',
      40: 'D20',
      38: 'D19',
      36: 'D18',
      34: 'D17',
      32: 'D16',
      30: 'D15',
      28: 'D14',
      26: 'D13',
      24: 'D12',
      22: 'D11',
      20: 'D10',
      18: 'D9',
      16: 'D8',
      14: 'D7',
      12: 'D6',
      10: 'D5',
      8: 'D4',
      6: 'D3',
      4: 'D2',
      2: 'D1',
    };
    
    return finishes[score];
  }

  void _undo() {
    if (history.isEmpty) return;
    final last = history.removeLast();
    setState(() {
      scores[last.player] = last.remaining + last.scored;
      currentPlayerIndex = players.indexOf(last.player);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Scoring • ${widget.gameMode}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause_circle),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            height: 44,
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
              tabs: const [
                Tab(text: 'Keypad', height: 40),
                Tab(text: 'Quick', height: 40),
                Tab(text: 'Dartboard', height: 40),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _ScoreHeader(
              players: players,
              scores: scores,
              currentPlayerIndex: currentPlayerIndex,
              startingScore: startingScore,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _KeypadPane(
                  pendingScore: pendingScore,
                  onNumber: _addScore,
                  onBackspace: _backspace,
                  onSubmit: _submitScore,
                  canSubmit: pendingScore >= 0 && pendingScore <= 180,
                ),
                _QuickScoresPane(
                  pendingScore: pendingScore,
                  onScoreTap: (int score) {
                    setState(() {
                      pendingScore = score;
                    });
                  },
                  onSubmit: _submitScore,
                  canSubmit: pendingScore >= 0 && pendingScore <= 180,
                ),
                _DartboardPane(
                  onSegmentTap: (int segment, int multiplier) {
                    final value = segment == 25 ? (multiplier == 2 ? 50 : 25) : segment * multiplier;
                    setState(() {
                      pendingScore = value;
                    });
                  },
                  onSubmit: _submitScore,
                  canSubmit: pendingScore >= 0 && pendingScore <= 180,
                  pendingScore: pendingScore,
                ),
              ],
            ),
          ),
          _HistoryPane(history: history, onUndo: _undo),
        ],
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.players, required this.scores, required this.currentPlayerIndex, required this.startingScore});

  final List<String> players;
  final Map<String, int> scores;
  final int currentPlayerIndex;
  final int startingScore;

  String? _getFinishRecommendation(int score) {
    // Common finish combinations
    final finishes = <int, String>{
      170: 'T20, T20, Bull',
      167: 'T20, T19, Bull',
      164: 'T20, T18, Bull',
      161: 'T20, T17, Bull',
      160: 'T20, T20, D20',
      157: 'T20, T19, D20',
      156: 'T20, T20, D18',
      154: 'T20, T18, D20',
      153: 'T20, T19, D18',
      151: 'T20, T17, D20',
      150: 'T20, T18, D18',
      148: 'T20, T20, D14',
      147: 'T20, T17, D18',
      145: 'T20, T19, D14',
      144: 'T20, T20, D12',
      141: 'T20, T19, D12',
      140: 'T20, T20, D10',
      138: 'T20, T18, D12',
      137: 'T20, T19, D10',
      136: 'T20, T20, D8',
      134: 'T20, T14, D16',
      132: 'Bull, Bull, D16',
      131: 'T20, T13, D16',
      130: 'T20, T18, D8',
      128: 'T18, T14, D16',
      127: 'T20, T17, D8',
      126: 'T19, T19, D6',
      124: 'T20, T14, D11',
      121: 'T20, T11, D14',
      120: 'T20, 20, D20',
      118: 'T20, 18, D20',
      116: 'T20, 16, D20',
      114: 'T20, 14, D20',
      112: 'T20, 12, D20',
      110: 'T20, 10, D20',
      108: 'T20, 8, D20',
      106: 'T20, 6, D20',
      104: 'T20, 4, D20',
      102: 'T20, 2, D20',
      101: 'T17, 10, D20',
      100: 'T20, D20',
      98: 'T20, D19',
      96: 'T20, D18',
      94: 'T18, D20',
      92: 'T20, D16',
      90: 'T18, D18',
      88: 'T16, D20',
      86: 'T18, D16',
      84: 'T20, D12',
      82: 'Bull, D16',
      80: 'T20, D10',
      78: 'T18, D12',
      76: 'T20, D8',
      74: 'T14, D16',
      72: 'T16, D12',
      70: 'T18, D8',
      68: 'T20, D4',
      64: 'T16, D8',
      60: '20, D20',
      56: 'T16, D4',
      52: '12, D20',
      50: 'Bull',
      48: '16, D16',
      40: 'D20',
      32: 'D16',
      24: 'D12',
      20: 'D10',
      16: 'D8',
      12: 'D6',
      8: 'D4',
      4: 'D2',
      2: 'D1',
    };
    return finishes[score];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: players.map((p) {
        final isActive = players.indexOf(p) == currentPlayerIndex;
        final playerScore = scores[p] ?? startingScore;
        final finishTip = playerScore <= 170 ? _getFinishRecommendation(playerScore) : null;
        
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: EdgeInsets.only(right: players.last == p ? 0 : AppSpacing.sm),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withOpacity(0.2) : AppColors.bgCard,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              border: Border.all(color: isActive ? AppColors.primary : AppColors.bgLight.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  p,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: isActive ? AppColors.primary : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$playerScore',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: isActive ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                if (finishTip != null && isActive) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    finishTip,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.secondary,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _KeypadPane extends StatelessWidget {
  const _KeypadPane({
    required this.pendingScore,
    required this.onNumber,
    required this.onBackspace,
    required this.onSubmit,
    required this.canSubmit,
  });

  final int pendingScore;
  final void Function(int) onNumber;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9],
      ['CLR', 0, '⌫'],
    ];

    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text('Pending: $pendingScore', style: AppTextStyles.headlineMedium),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final row = index ~/ 3;
              final col = index % 3;
              final label = buttons[row][col];
              return ElevatedButton(
                onPressed: () {
                  if (label == 'CLR') {
                    // Clear all (set to 0)
                    onNumber(0);
                    onBackspace();
                    return;
                  }
                  if (label == '⌫') {
                    onBackspace();
                    return;
                  }
                  onNumber(label as int);
                },
                child: Text('$label'),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canSubmit ? onSubmit : null,
              child: const Text('Submit'),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickScoresPane extends StatelessWidget {
  const _QuickScoresPane({
    required this.pendingScore,
    required this.onScoreTap,
    required this.onSubmit,
    required this.canSubmit,
  });

  final int pendingScore;
  final void Function(int) onScoreTap;
  final VoidCallback onSubmit;
  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    // Combine preset scores and single numbers 0-20
    final List<int> scores = [
      0, // Zero is valid in darts
      ...List.generate(20, (i) => i + 1), // 1-20
      ...GameScoringScreen.commonScores, // 40, 60, 75, 80, 85, 90, 95, 100, 110, 120, 121, 125, 133, 135, 140, 170, 180
    ];
    scores.sort();

    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text('Selected: $pendingScore', style: AppTextStyles.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            itemCount: scores.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final score = scores[index];
              final isSelected = pendingScore == score;
              return GestureDetector(
                onTap: () => onScoreTap(score),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [AppColors.secondary, AppColors.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : AppColors.bgLight.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$score',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canSubmit ? onSubmit : null,
              child: const Text('Submit'),
            ),
          ),
        ),
      ],
    );
  }
}

class _DartboardPane extends StatelessWidget {
  const _DartboardPane({
    required this.onSegmentTap,
    required this.onSubmit,
    required this.canSubmit,
    required this.pendingScore,
  });

  final void Function(int segment, int multiplier) onSegmentTap;
  final VoidCallback onSubmit;
  final bool canSubmit;
  final int pendingScore;

  @override
  Widget build(BuildContext context) {
    final segments = [
      20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5,
    ];
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text('Tap a segment', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              for (final seg in segments)
                _SegmentPill(
                  label: 'T$seg',
                  color: AppColors.error,
                  onTap: () => onSegmentTap(seg, 3),
                ),
              for (final seg in segments)
                _SegmentPill(
                  label: 'D$seg',
                  color: AppColors.primary,
                  onTap: () => onSegmentTap(seg, 2),
                ),
              for (final seg in segments)
                _SegmentPill(
                  label: '$seg',
                  color: AppColors.accent,
                  onTap: () => onSegmentTap(seg, 1),
                ),
              _SegmentPill(label: 'SBull', color: AppColors.secondary, onTap: () => onSegmentTap(25, 1)),
              _SegmentPill(label: 'DBull', color: AppColors.secondary, onTap: () => onSegmentTap(25, 2)),
            ],
          ),
          const Spacer(),
          Text('Pending: $pendingScore', style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canSubmit ? onSubmit : null,
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentPill extends StatelessWidget {
  const _SegmentPill({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          border: Border.all(color: color.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(AppBorderRadius.full),
        ),
        child: Text(label, style: AppTextStyles.labelLarge.copyWith(color: color)),
      ),
    );
  }
}

class _HistoryPane extends StatelessWidget {
  const _HistoryPane({required this.history, required this.onUndo});

  final List<_ThrowEntry> history;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.bgLight.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final item = history.reversed.elementAt(index);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: item.isBust ? AppColors.error.withOpacity(0.15) : AppColors.bgLight,
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      border: Border.all(
                        color: item.isBust ? AppColors.error : AppColors.bgLight.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.player, style: AppTextStyles.labelLarge),
                        Text(
                          item.isBust ? 'BUST' : '-${item.scored} → ${item.remaining}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: item.isBust ? AppColors.error : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemCount: history.length,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          IconButton(
            onPressed: onUndo,
            icon: const Icon(Icons.undo, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _ThrowEntry {
  _ThrowEntry({required this.player, required this.scored, required this.remaining, required this.isBust});

  final String player;
  final int scored;
  final int remaining;
  final bool isBust;
}
