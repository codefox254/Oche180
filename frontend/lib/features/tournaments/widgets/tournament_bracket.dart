import 'package:flutter/material.dart';
import '../models/tournament.dart';

class TournamentBracket extends StatelessWidget {
  final List<TournamentRound> rounds;
  final Function(TournamentMatch)? onMatchTap;

  const TournamentBracket({
    super.key,
    required this.rounds,
    this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    if (rounds.isEmpty) {
      return const Center(
        child: Text('No bracket available'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rounds.map((round) {
              return _BracketRound(
                round: round,
                onMatchTap: onMatchTap,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _BracketRound extends StatelessWidget {
  final TournamentRound round;
  final Function(TournamentMatch)? onMatchTap;

  const _BracketRound({
    required this.round,
    this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Round header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            round.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Matches
        Column(
          children: round.matches.map((match) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _MatchCard(
                match: match,
                onTap: () => onMatchTap?.call(match),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final TournamentMatch match;
  final VoidCallback? onTap;

  const _MatchCard({
    required this.match,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 24),
      child: Card(
        elevation: match.isCompleted ? 1 : 3,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: match.isInProgress
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
            ),
            child: Column(
              children: [
                // Match header
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getMatchStatusColor(context).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Match ${match.matchNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getMatchStatusColor(context),
                        ),
                      ),
                      _MatchStatusBadge(match: match),
                    ],
                  ),
                ),
                
                // Players
                if (match.hasPlayers)
                  Column(
                    children: [
                      _PlayerRow(
                        playerName: match.player1Name ?? 'Player 1',
                        score: match.player1Score,
                        isWinner: match.winnerId == match.player1Id,
                        isCompleted: match.isCompleted,
                      ),
                      const Divider(height: 1),
                      _PlayerRow(
                        playerName: match.player2Name ?? 'Player 2',
                        score: match.player2Score,
                        isWinner: match.winnerId == match.player2Id,
                        isCompleted: match.isCompleted,
                      ),
                    ],
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      match.isBye ? 'BYE' : 'TBD',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getMatchStatusColor(BuildContext context) {
    if (match.isCompleted) return Colors.green;
    if (match.isInProgress) return Colors.blue;
    if (match.isWalkover) return Colors.orange;
    return Colors.grey;
  }
}

class _PlayerRow extends StatelessWidget {
  final String playerName;
  final int? score;
  final bool isWinner;
  final bool isCompleted;

  const _PlayerRow({
    required this.playerName,
    this.score,
    required this.isWinner,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isWinner && isCompleted
            ? Colors.green.withOpacity(0.1)
            : null,
      ),
      child: Row(
        children: [
          if (isWinner && isCompleted)
            const Icon(
              Icons.emoji_events,
              size: 16,
              color: Colors.amber,
            ),
          if (isWinner && isCompleted) const SizedBox(width: 8),
          Expanded(
            child: Text(
              playerName,
              style: TextStyle(
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: isWinner && isCompleted
                    ? Colors.green.shade800
                    : null,
              ),
            ),
          ),
          if (score != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isWinner
                    ? Colors.green
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                score.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isWinner ? Colors.white : Colors.black87,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MatchStatusBadge extends StatelessWidget {
  final TournamentMatch match;

  const _MatchStatusBadge({required this.match});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;

    if (match.isCompleted) {
      text = 'Completed';
      color = Colors.green;
    } else if (match.isInProgress) {
      text = 'Live';
      color = Colors.blue;
    } else if (match.isWalkover) {
      text = 'Walkover';
      color = Colors.orange;
    } else if (match.isBye) {
      text = 'Bye';
      color = Colors.grey;
    } else {
      text = 'Pending';
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
