import 'dart:convert';
import 'package:http/http.dart' as http;

class GameResultsService {
  final String baseUrl;

  GameResultsService({this.baseUrl = 'http://127.0.0.1:8000/api'});

  Future<Map<String, dynamic>> submitGameResult({
    required String token,
    required String gameType,
    required bool isTraining,
    required Map<String, dynamic> gameSettings,
    required List<Map<String, dynamic>> players,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/games/submit_game_result/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'game_type': gameType,
          'is_training': isTraining,
          'game_settings': gameSettings,
          'players': players,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to submit game result: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error submitting game result: $e');
    }
  }

  /// Helper method to format player result data
  static Map<String, dynamic> formatPlayerResult({
    required String name,
    required int finalScore,
    int finalPosition = 1,
    bool isWinner = false,
    bool isCurrentUser = false,
    Map<String, dynamic>? statistics,
    Map<String, dynamic>? detailedStats,
  }) {
    return {
      'name': name,
      'final_score': finalScore,
      'final_position': finalPosition,
      'is_winner': isWinner,
      'is_current_user': isCurrentUser,
      'statistics': statistics ?? {},
      'detailed_stats': detailedStats ?? {},
    };
  }

  /// Helper method to format detailed game statistics
  static Map<String, dynamic> formatDetailedStats({
    required int totalThrows,
    required double averagePerDart,
    required double averagePerRound,
    int checkoutAttempts = 0,
    int checkoutSuccesses = 0,
    double checkoutPercentage = 0,
    int count180s = 0,
    int count140Plus = 0,
    int count100Plus = 0,
    int highestScore = 0,
    double? marksPerRound,
  }) {
    return {
      'total_throws': totalThrows,
      'average_per_dart': averagePerDart,
      'average_per_round': averagePerRound,
      'checkout_attempts': checkoutAttempts,
      'checkout_successes': checkoutSuccesses,
      'checkout_percentage': checkoutPercentage,
      'count_180s': count180s,
      'count_140_plus': count140Plus,
      'count_100_plus': count100Plus,
      'highest_score': highestScore,
      'marks_per_round': marksPerRound,
    };
  }
}
