import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:silatik_mobile/core/constants/api_endpoints.dart';
import 'package:silatik_mobile/data/services/latik_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late LatikService service;

  setUp(() {
    dio = MockDio();
    service = LatikService(dio);
  });

  test('getRevisiExt calls GET /latikext/revisi and returns list', () async {
    when(() => dio.get(ApiEndpoints.latikExtRevision)).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ApiEndpoints.latikExtRevision),
        data: {
          'code': 200,
          'data': [
            {'ref_ext': 'EXT-001', 'status': 2},
            {'ref_ext': 'EXT-002', 'status': 2},
          ],
        },
      ),
    );

    final result = await service.getRevisiExt();
    expect(result.length, 2);
    expect(result.last['ref_ext'], 'EXT-002');
  });
}
