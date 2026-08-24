import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/core/utils/api_error_handler.dart';

void main() {
  group('ApiErrorHandler.getMessage', () {
    test('returns server message for map response', () {
      final error = DioException(
        requestOptions: RequestOptions(path: 'x'),
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: 'x'),
          data: {'message': 'Terjadi kesalahan pada server'},
        ),
      );
      expect(ApiErrorHandler.getMessage(error), 'Terjadi kesalahan pada server');
    });

    test('falls back to error key when message is absent', () {
      final error = DioException(
        requestOptions: RequestOptions(path: 'x'),
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: 'x'),
          data: {'error': 'Internal Server Error'},
        ),
      );
      expect(ApiErrorHandler.getMessage(error), 'Internal Server Error');
    });

    test('falls back to msg key when message and error are absent', () {
      final error = DioException(
        requestOptions: RequestOptions(path: 'x'),
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: 'x'),
          data: {'msg': 'Server busy'},
        ),
      );
      expect(ApiErrorHandler.getMessage(error), 'Server busy');
    });

    test('returns generic message when response map has no known keys', () {
      final error = DioException(
        requestOptions: RequestOptions(path: 'x'),
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: 'x'),
          data: {'unexpected': 'shape'},
        ),
      );
      expect(ApiErrorHandler.getMessage(error), 'Terjadi kesalahan pada server');
    });

    test('returns connection timeout message', () {
      final error = DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: 'x'),
      );
      expect(ApiErrorHandler.getMessage(error),
          'Koneksi timeout. Periksa jaringan Anda.');
    });

    test('returns receive timeout message', () {
      final error = DioException(
        type: DioExceptionType.receiveTimeout,
        requestOptions: RequestOptions(path: 'x'),
      );
      expect(ApiErrorHandler.getMessage(error),
          'Server tidak merespons. Coba lagi.');
    });

    test('returns connection error message', () {
      final error = DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: 'x'),
      );
      expect(ApiErrorHandler.getMessage(error),
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    });

    test('returns default message for unknown error', () {
      final error = DioException(
        type: DioExceptionType.unknown,
        requestOptions: RequestOptions(path: 'x'),
      );
      expect(ApiErrorHandler.getMessage(error),
          'Terjadi kesalahan. Silakan coba lagi.');
    });
  });
}
