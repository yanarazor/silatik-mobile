import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:silatik_mobile/data/services/master_data_service.dart';

import '../../helpers/mock_helpers.dart';

void main() {
  late MockDio mockDio;
  late MasterDataService service;

  setUp(() {
    mockDio = MockDio();
    service = MasterDataService(mockDio);
  });

  group('MasterDataService.getAgama', () {
    test('maps agama list from data envelope', () async {
      // Bentuk respons nyata: nama ada di key `value`.
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse({
          'code': 200,
          'success': true,
          'data': [
            {'id': 1, 'value': 'Islam'},
            {'id': 2, 'value': 'Kristen Protestan'},
          ],
        }),
      );

      final result = await service.getAgama();
      expect(result, hasLength(2));
      expect(result.first.id, '1');
      expect(result.first.nama, 'Islam');
      verify(() => mockDio.get('masters/agama')).called(1);
    });
  });
}
