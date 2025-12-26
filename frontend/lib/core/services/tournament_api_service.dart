import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TournamentApiService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<dynamic>> getTournaments(String token, {String? status}) async {
    final uri = status != null
        ? Uri.parse('$baseUrl/api/tournaments/?status=$status')
        : Uri.parse('$baseUrl/api/tournaments/');

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      // Only add authorization if token is provided
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is List ? data : [];
      } else if (response.statusCode == 401 || response.statusCode == 404) {
        // Return empty list for unauthorized or not found instead of throwing
        return [];
      } else {
        // For other errors, return empty list gracefully
        return [];
      }
    } catch (e) {
      // Return empty list on any error
      return [];
    }
  }

  Future<Map<String, dynamic>> getTournamentDetails(
    String token,
    int tournamentId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tournaments/$tournamentId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load tournament details: ${response.body}');
    }
  }

  Future<List<dynamic>> getTournamentMatches(
    String token,
    int tournamentId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tournaments/$tournamentId/matches/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load matches: ${response.body}');
    }
  }

  Future<List<dynamic>> getTournamentStandings(
    String token,
    int tournamentId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tournaments/$tournamentId/standings/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load standings: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> joinTournament(
    String token,
    int tournamentId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tournaments/$tournamentId/join/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to join tournament: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createTournament(
    String token,
    Map<String, dynamic> tournamentData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/tournaments/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(tournamentData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create tournament: ${response.body}');
    }
  }

  Future<List<dynamic>> getLiveMatches(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tournaments/live-matches/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load live matches: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateMatchScore(
    String token,
    int matchId,
    Map<String, dynamic> scoreData,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/tournaments/matches/$matchId/score/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(scoreData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update match score: ${response.body}');
    }
  }
}
