import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class StatisticsService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>> getUserStatistics(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/stats/summary/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load statistics: ${response.body}');
    }
  }

  Future<List<dynamic>> getRecentGames(String token, {int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/games/recent/?limit=$limit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load recent games: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getGameModeStatistics(
    String token,
    String gameMode,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/stats/game-mode/$gameMode/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load game mode statistics: ${response.body}');
    }
  }

  Future<List<dynamic>> getAchievements(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/stats/achievements/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load achievements: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getProgressData(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/stats/progress/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load progress data: ${response.body}');
    }
  }
}
