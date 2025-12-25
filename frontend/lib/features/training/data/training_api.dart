import 'dart:convert';
import 'package:http/http.dart' as http;

class TrainingApi {
  TrainingApi({required this.baseUrl, this.authToken});

  final String baseUrl; // e.g., http://127.0.0.1:8000/api
  final String? authToken;

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  Future<List<Map<String, dynamic>>> fetchPrograms() async {
    final res = await http.get(Uri.parse('$baseUrl/training/programs/'), headers: _headers);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load programs: ${res.statusCode}');
  }

  Future<List<Map<String, dynamic>>> fetchDrills() async {
    final res = await http.get(Uri.parse('$baseUrl/training/drills/'), headers: _headers);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load drills: ${res.statusCode}');
  }

  Future<List<Map<String, dynamic>>> fetchChallenges() async {
    final res = await http.get(Uri.parse('$baseUrl/training/challenges/'), headers: _headers);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load challenges: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> startSession({
    required String mode,
    Map<String, dynamic>? settings,
    int? durationMinutes,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/training/sessions/'),
      headers: _headers,
      body: jsonEncode({
        'mode': mode,
        'settings': settings ?? {},
        'duration_minutes': durationMinutes ?? 30,  // Default 30 minutes
      }),
    );
    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to start session: ${res.statusCode}');
  }

  Future<void> recordThrow({required int sessionId, required int throwNumber, required int target, required int score, required bool hit}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/training/throws/'),
      headers: _headers,
      body: jsonEncode({
        'session': sessionId,
        'throw_number': throwNumber,
        'target': target,
        'score': score,
        'hit': hit,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception('Failed to record throw: ${res.statusCode}');
    }
  }

  Future<Map<String, dynamic>> completeSession({
    required int sessionId,
    int? finalScore,
    double? successRate,
    int? elapsedSeconds,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/training/sessions/$sessionId/complete/'),
      headers: _headers,
      body: jsonEncode({
        if (finalScore != null) 'final_score': finalScore,
        if (successRate != null) 'success_rate': successRate,
        if (elapsedSeconds != null) 'elapsed_seconds': elapsedSeconds,
      }),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to complete session: ${res.statusCode}');
  }

  Future<List<dynamic>> personalBests() async {
    final res = await http.get(Uri.parse('$baseUrl/training/personal-bests/'), headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Failed to load personal bests: ${res.statusCode}');
  }
}
