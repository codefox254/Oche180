import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService {
  final String baseUrl;

  AuthService({this.baseUrl = 'http://127.0.0.1:8000/api'});

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    // TODO: Replace with actual JWT endpoint when backend is ready
    // For now, simulate a successful login
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': identifier,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> signup({
    required String email,
    required String username,
    required String password,
  }) async {
    // TODO: Replace with actual registration endpoint
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Signup failed: ${response.body}');
    }
  }

  Future<User> getCurrentUser(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/user/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get user: ${response.body}');
    }
  }

  Future<User> updateProfile(String token, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/auth/user/update/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  Future<String> uploadAvatar(String token, String imagePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/auth/avatar/'),
    );
    request.headers['Authorization'] = 'Token $token';
    request.files.add(await http.MultipartFile.fromPath('avatar', imagePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['avatar_url'] as String;
    } else {
      throw Exception('Failed to upload avatar: ${response.body}');
    }
  }
}
