import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/auth_service.dart';
import '../data/services/storage_service.dart';
import '../data/services/api_client.dart';
import '../core/utils/api_error_handler.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? token;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthState(
      {this.isLoggedIn = false,
      this.isLoading = false,
      this.token,
      this.user,
      this.error});

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? token,
    Map<String, dynamic>? user,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo, this._storage) : super(const AuthState());
  final AuthRepository _repo;
  final StorageService _storage;

  Future<void> checkAuth() async {
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final res = await _repo.getMe();
        final user = _extractUser(res);
        state = state.copyWith(isLoggedIn: true, token: token, user: user);
      } catch (e) {
        await logout();
      }
    }
  }

  Future<void> login(String username, String password) async {
    debugPrint('[AUTH_PROVIDER] login start for: $username');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.login(username, password);
      debugPrint('[AUTH_PROVIDER] login response: $res');
      final result = res['result'];
      final token = result?['access_token'];
      final user = _extractUser(res);

      if (token != null) {
        await _storage.saveToken(token);
        debugPrint('[AUTH_PROVIDER] token saved, login success');
        state = state.copyWith(
            isLoading: false, isLoggedIn: true, token: token, user: user);
      } else {
        debugPrint('[AUTH_PROVIDER] token null / invalid format');
        state =
            state.copyWith(isLoading: false, error: 'Format token tidak valid');
      }
    } catch (e) {
      debugPrint('[AUTH_PROVIDER] login error: $e');
      String errorMessage = e.toString();
      if (e is DioException) {
        debugPrint('[AUTH_PROVIDER] dio status: ${e.response?.statusCode}');
        debugPrint('[AUTH_PROVIDER] dio body: ${e.response?.data}');
        errorMessage = ApiErrorHandler.getMessage(e);
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<void> register(Map<String, dynamic> payload) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.register(payload);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException) {
        errorMessage = ApiErrorHandler.getMessage(e);
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.forgotPassword(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException) {
        errorMessage = ApiErrorHandler.getMessage(e);
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      rethrow;
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _repo.changePassword(oldPassword, newPassword);
    } catch (e) {
      if (e is DioException) {
        throw ApiErrorHandler.getMessage(e);
      }
      throw e.toString();
    }
  }

  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (e) {
      debugPrint('[AUTH_PROVIDER] server logout failed (continuing local): $e');
    }
    await _storage.deleteToken();
    ApiClient.dio.options.headers.remove('Authorization');
    state = const AuthState();
  }

  Map<String, dynamic>? _extractUser(Map<String, dynamic> response) {
    final result = response['result'];
    if (result is Map<String, dynamic>) {
      final userData = result['user_data'];
      if (userData is Map<String, dynamic>) return userData;
      final data = result['data'];
      if (data is Map<String, dynamic>) return data;
    }
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    final userData = response['user_data'];
    if (userData is Map<String, dynamic>) return userData;
    debugPrint('[AUTH_PROVIDER] no user data found in response');
    return null;
  }
}

final storageProvider = Provider((ref) => StorageService());
final dioProvider = Provider((ref) {
  final dio = ApiClient.dio;
  final hasAuthInterceptor = dio.interceptors.any((i) => i is QueuedInterceptorsWrapper);
  if (!hasAuthInterceptor) {
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final path = options.path.toLowerCase();
          final isPublicAuthEndpoint = path.endsWith('login') ||
              path.endsWith('createuser') ||
              path.contains('forgot-password');

          if (!isPublicAuthEndpoint) {
            final token = await ref.watch(storageProvider).getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
      ),
    );
  }
  return dio;
});
final authServiceProvider = Provider((ref) => AuthService(ref.watch(dioProvider)));
final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(authServiceProvider)));
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider), ref.watch(storageProvider)),
);
