import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/api_endpoints.dart';

class AuthService {
  final Dio _dio;
  AuthService(this._dio);

  Future<Map<String, dynamic>> login(String username, String password) async {
    final baseUrl = _dio.options.baseUrl;
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final useApiPrefix = !normalizedBase.contains('/api/');
    final loginPath = useApiPrefix ? 'api/login' : 'login';

    final loginDio = Dio(
      BaseOptions(
        baseUrl: normalizedBase,
        connectTimeout: _dio.options.connectTimeout,
        receiveTimeout: _dio.options.receiveTimeout,
        headers: {
          'Accept': '*/*',
          'Content-Type': 'application/json',
          'X-App-Client': 'flutter-silatik',
        },
      ),
    );

    debugPrint('[AUTH] login() called');
    debugPrint('[AUTH] baseUrl: $normalizedBase');
    debugPrint('[AUTH] endpoint: $loginPath');
    debugPrint('[AUTH] username: ${username.trim()}');
    debugPrint('[AUTH] headers: ${loginDio.options.headers}');

    final response = await loginDio.post(loginPath, data: {
      'username': username.trim(),
      'password': password.trim(),
    });

    debugPrint('[AUTH] login response raw: ${response.data}');
    return response.data;
  }

  Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String password,
    required String noHp,
  }) async {
    final response = await _dio.post(ApiEndpoints.register, data: {
      'name': nama,
      'email': email,
      'password': password,
      'password_confirmation': password,
      'no_hp': noHp,
    });
    return response.data;
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _dio.post(ApiEndpoints.changePassword, data: {
      'old_password': oldPassword,
      'new_password': newPassword,
      'new_password_confirmation': newPassword,
    });
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get(ApiEndpoints.userMe);
    return response.data;
  }
}
