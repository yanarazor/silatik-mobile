import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ApiErrorHandler {
  static String messageFrom(Object? error) {
    if (error is DioException) return getMessage(error);
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  static String getMessage(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      // Try common Laravel error response patterns
      if (data is Map) {
        final raw = data['message'] ?? data['error'] ?? data['msg'];
        if (raw is String && raw.trim().isNotEmpty) {
          return _clean(raw);
        }
        return 'Terjadi kesalahan pada server';
      }
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Koneksi timeout. Periksa jaringan Anda.';
      case DioExceptionType.receiveTimeout:
        return 'Server tidak merespons. Coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      default:
        return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }

  static String _clean(String message) => message.split('|').first.trim();

  static void showSnackBar(BuildContext context, DioException error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getMessage(error)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
