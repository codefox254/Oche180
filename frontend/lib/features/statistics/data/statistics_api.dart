import 'dart:convert';
import 'package:http/http.dart' as http;

class StatisticsApi {
  final String baseUrl;
  final String? authToken;

  StatisticsApi({required this.baseUrl, this.authToken});

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  Future<Map<String, dynamic>> fetchStatsSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/stats/summary/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load stats summary: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPersonalBests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/stats/personal-bests/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load personal bests: ${response.statusCode}');
    }
  }
}
