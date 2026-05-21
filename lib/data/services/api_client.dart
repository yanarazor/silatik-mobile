import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  ApiClient._();
  static String _normalizeBaseUrl(String raw) {
    var trimmed = raw.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (!trimmed.toLowerCase().endsWith('/api')) {
      trimmed = '$trimmed/api';
    }
    return '$trimmed/';
  }

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: _normalizeBaseUrl(
        dotenv.env['API_BASE_URL'] ?? 'https://silatik.brin.go.id/api/',
      ),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-App-Client': 'flutter-silatik',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('[API][REQ] ${options.method} ${options.baseUrl}/${options.path}');
          debugPrint('[API][REQ][HEADERS] ${options.headers}');
          debugPrint('[API][REQ][BODY] ${options.data}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('[API][RES] ${response.statusCode} ${response.requestOptions.path}');
          debugPrint('[API][RES][BODY] ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('[API][ERR] ${error.response?.statusCode} ${error.requestOptions.path}');
          debugPrint('[API][ERR][MSG] ${error.message}');
          debugPrint('[API][ERR][BODY] ${error.response?.data}');
          handler.next(error);
        },
      ),
    );
}
