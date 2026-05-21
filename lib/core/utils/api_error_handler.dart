import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ApiErrorHandler {
  static String getMessage(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      // Try common Laravel error response patterns
      if (data is Map) {
        return data['message'] ??
            data['error'] ??
            data['msg'] ??
            'Terjadi kesalahan pada server';
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
