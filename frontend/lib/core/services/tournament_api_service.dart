import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TournamentApiService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<dynamic>> getTournaments(String token, {String? status}) async {
    final uri = status != null
        ? Uri.parse('$baseUrl/api/tournaments/?status=$status')
        : Uri.parse('$baseUrl/api/tournaments/');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load tournaments: ${response.body}');
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
