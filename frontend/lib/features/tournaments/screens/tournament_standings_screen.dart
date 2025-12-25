import 'package:flutter/material.dart';
import '../services/tournament_service.dart';
import '../../../core/services/api_service.dart';

class TournamentStanding {
  final int rank;
  final String playerName;
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final int pointsFor;
  final int pointsAgainst;
  final int pointsDifference;
  final int tournamentPoints;
  final double averageScore;
  final double winRate;

  TournamentStanding({
    required this.rank,
    required this.playerName,
    required this.matchesPlayed,
    required this.matchesWon,
    required this.matchesLost,
    required this.pointsFor,
    required this.pointsAgainst,
    required this.pointsDifference,
    required this.tournamentPoints,
    required this.averageScore,
    required this.winRate,
  });

  factory TournamentStanding.fromJson(Map<String, dynamic> json) {
    return TournamentStanding(
      rank: json['rank'],
      playerName: json['player_name'] ?? 'Unknown',
      matchesPlayed: json['matches_played'],
      matchesWon: json['matches_won'],
      matchesLost: json['matches_lost'],
      pointsFor: json['points_for'],
      pointsAgainst: json['points_against'],
      pointsDifference: json['points_difference'],
      tournamentPoints: json['tournament_points'],
      averageScore: double.parse(json['average_score'].toString()),
      winRate: double.parse(json['win_rate'].toString()),
    );
  }
}

class TournamentStandingsScreen extends StatefulWidget {
  final int tournamentId;

  const TournamentStandingsScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  State<TournamentStandingsScreen> createState() => _TournamentStandingsScreenState();
}

class _TournamentStandingsScreenState extends State<TournamentStandingsScreen> {
  late TournamentService _tournamentService;
  
  List<TournamentStanding> _standings = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tournamentService = TournamentService(ApiService());
    _loadStandings();
  }

  Future<void> _loadStandings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final standings = await _tournamentService.getTournamentStandings(widget.tournamentId);
      
      setState(() {
        _standings = standings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getRankIcon(int rank) {
    if (rank <= 3) {
      return Icons.emoji_events;
    }
    return Icons.person;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Standings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStandings,
          ),
        ],
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
                        onPressed: _loadStandings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _standings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.leaderboard,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No standings available yet',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStandings,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Top 3 Podium
                            if (_standings.length >= 3) _buildPodium(),
                            
                            // Table Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                border: Border(
                                  bottom: BorderSide(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 40, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                                  const Expanded(flex: 3, child: Text('Player', style: TextStyle(fontWeight: FontWeight.bold))),
                                  const Expanded(child: Text('MP', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                  const Expanded(child: Text('W', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                  const Expanded(child: Text('L', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                  const Expanded(child: Text('Pts', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                ],
                              ),
                            ),
                            
                            // Standings List
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _standings.length,
                              itemBuilder: (context, index) {
                                return _buildStandingRow(_standings[index]);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildPodium() {
    final top3 = _standings.take(3).toList();
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (top3.length > 1) _buildPodiumPlace(top3[1], 2, 120),
          if (top3.isNotEmpty) _buildPodiumPlace(top3[0], 1, 160),
          if (top3.length > 2) _buildPodiumPlace(top3[2], 3, 100),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(TournamentStanding standing, int place, double height) {
    final colors = [Colors.amber, Colors.grey.shade400, Colors.orange.shade700];
    final color = colors[place - 1];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events,
            color: color,
            size: place == 1 ? 48 : 32,
          ),
          const SizedBox(height: 8),
          Text(
            standing.playerName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: place == 1 ? 16 : 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${standing.tournamentPoints} pts',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.8),
                  color.withOpacity(0.5),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Center(
              child: Text(
                '#$place',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandingRow(TournamentStanding standing) {
    return InkWell(
      onTap: () => _showStandingDetails(standing),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getRankIcon(standing.rank),
                    size: 20,
                    color: _getRankColor(standing.rank),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${standing.rank}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getRankColor(standing.rank),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                standing.playerName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Text(
                '${standing.matchesPlayed}',
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Text(
                '${standing.matchesWon}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                '${standing.matchesLost}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            Expanded(
              child: Text(
                '${standing.tournamentPoints}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStandingDetails(TournamentStanding standing) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getRankIcon(standing.rank),
                  color: _getRankColor(standing.rank),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      standing.playerName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Rank #${standing.rank}',
                      style: TextStyle(
                        color: _getRankColor(standing.rank),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const Divider(height: 32),
            
            _buildStatRow('Matches Played', '${standing.matchesPlayed}'),
            _buildStatRow('Wins', '${standing.matchesWon}', valueColor: Colors.green),
            _buildStatRow('Losses', '${standing.matchesLost}', valueColor: Colors.red),
            _buildStatRow('Win Rate', '${standing.winRate.toStringAsFixed(1)}%'),
            const SizedBox(height: 16),
            _buildStatRow('Points For', '${standing.pointsFor}'),
            _buildStatRow('Points Against', '${standing.pointsAgainst}'),
            _buildStatRow('Points Difference', '${standing.pointsDifference >= 0 ? '+' : ''}${standing.pointsDifference}'),
            _buildStatRow('Average Score', standing.averageScore.toStringAsFixed(1)),
            const SizedBox(height: 16),
            _buildStatRow('Tournament Points', '${standing.tournamentPoints}', 
                         valueColor: Theme.of(context).primaryColor,
                         valueSize: 20,
                         valueBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor, double? valueSize, bool valueBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
              fontSize: valueSize,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
