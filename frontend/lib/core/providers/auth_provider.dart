import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null && token != null;
  bool get isGuest => !isAuthenticated;

  AuthState copyWith({
    User? user,
    String? token,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearToken = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      token: clearToken ? null : (token ?? this.token),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final AuthService _authService = AuthService();

  @override
  AuthState build() {
    _loadSession();
    return const AuthState();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(isLoading: true);
      try {
        final user = await _authService.getCurrentUser(token);
        state = state.copyWith(
          user: user,
          token: token,
          isLoading: false,
          clearError: true,
        );
      } catch (e) {
        // Token invalid, clear it
        await prefs.remove('auth_token');
        state = state.copyWith(isLoading: false, clearUser: true, clearToken: true);
      }
    }
  }

  Future<void> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.login(identifier, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', result['token']);
      
      final user = await _authService.getCurrentUser(result['token']);
      state = state.copyWith(
        user: user,
        token: result['token'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> signup({
    required String email,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.signup(
        email: email,
        username: username,
        password: password,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', result['token']);
      
      final user = await _authService.getCurrentUser(result['token']);
      state = state.copyWith(
        user: user,
        token: result['token'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    state = const AuthState();
  }

  Future<void> refreshUser() async {
    if (state.token != null) {
      try {
        final user = await _authService.getCurrentUser(state.token!);
        state = state.copyWith(user: user);
      } catch (e) {
        // Token might be expired
        await logout();
      }
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (state.token == null) return;
    
    state = state.copyWith(isLoading: true);
    try {
      final updatedUser = await _authService.updateProfile(state.token!, data);
      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
