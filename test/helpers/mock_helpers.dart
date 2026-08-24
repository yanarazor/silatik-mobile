import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockBaseOptions extends Mock implements BaseOptions {}

Response<T> makeResponse<T>(T data, {int statusCode = 200, String path = ''}) {
  return Response<T>(
    data: data,
    statusCode: statusCode,
    requestOptions: RequestOptions(path: path),
  );
}

RequestOptions makeRequestOptions({String path = ''}) {
  return RequestOptions(path: path);
}

/// Loads a JSON fixture file from `test/fixtures/` as a decoded Dart object.
dynamic loadFixture(String name) {
  final file = File(
    '${Directory.current.path}/test/fixtures/$name',
  );
  if (!file.existsSync()) {
    throw StateError('Fixture not found: ${file.path}');
  }
  return jsonDecode(file.readAsStringSync());
}
