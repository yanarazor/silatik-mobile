import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:silatik_mobile/data/services/notifikasi_service.dart';

import '../../helpers/mock_helpers.dart';

void main() {
  late MockDio mockDio;
  late NotifikasiService notifikasiService;

  setUp(() {
    mockDio = MockDio();
    notifikasiService = NotifikasiService(mockDio);
  });

  group('NotifikasiService.getAll', () {
    test('returns list from single page real response', () async {
      final fixture = loadFixture('notification_all.json');
      when(() => mockDio.get(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => makeResponse(fixture));

      final result = await notifikasiService.getAll();
      expect(result, hasLength(1));
      expect(result.first['id'], '157c7fa5-b736-4bec-81a1-4e64f7929364');
      expect(result.first['data'], isA<Map>());
    });

    test('paginates through multiple pages', () async {
      when(() => mockDio.get(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((invocation) async {
        final params = invocation.namedArguments[#queryParameters] as Map;
        final page = params['page'] as int;
        if (page == 1) {
          return makeResponse({
            'code': 200,
            'success': true,
            'totalPages': 2,
            'data': [
              {'id': '1'},
            ],
          });
        }
        return makeResponse({
          'code': 200,
          'success': true,
          'totalPages': 2,
          'data': [
            {'id': '2'},
          ],
        });
      });

      final result = await notifikasiService.getAll();
      expect(result, hasLength(2));
      verify(() => mockDio.get(any(),
              queryParameters: any(named: 'queryParameters')))
          .called(2);
    });

    test('returns empty list for empty response', () async {
      when(() => mockDio.get(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async =>
              makeResponse({'result': [], 'totalPages': 1}));

      final result = await notifikasiService.getAll();
      expect(result, isEmpty);
    });
  });

  group('NotifikasiService.getUnread', () {
    test('returns unread notifications list', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse({
          'result': [
            {'id': '1', 'judul': 'Unread 1'},
          ],
        }),
      );

      final result = await notifikasiService.getUnread();
      expect(result, hasLength(1));
      verify(() => mockDio.get('notification/unread')).called(1);
    });
  });

  group('NotifikasiService.getUnreadCount', () {
    test('returns count from real unreadCount response', () async {
      final fixture = loadFixture('notification_unreadcount.json');
      when(() => mockDio.get(any())).thenAnswer((_) async =>
          makeResponse(fixture));

      final result = await notifikasiService.getUnreadCount();
      expect(result, 51);
    });

    test('returns count from int response', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse(5),
      );

      final result = await notifikasiService.getUnreadCount();
      expect(result, 5);
    });

    test('returns count from map with result key', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse({'result': 3}),
      );

      final result = await notifikasiService.getUnreadCount();
      expect(result, 3);
    });

    test('returns count from map with count key', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse({'count': 7}),
      );

      final result = await notifikasiService.getUnreadCount();
      expect(result, 7);
    });

    test('returns count from map with total key', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse({'total': 10}),
      );

      final result = await notifikasiService.getUnreadCount();
      expect(result, 10);
    });

    test('parses string count to int', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse({'count': '4'}),
      );

      final result = await notifikasiService.getUnreadCount();
      expect(result, 4);
    });

    test('returns 0 for unrecognized format', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse('unexpected'),
      );

      final result = await notifikasiService.getUnreadCount();
      expect(result, 0);
    });
  });

  group('NotifikasiService.markAllAsRead', () {
    test('calls correct endpoint', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse(null),
      );

      await notifikasiService.markAllAsRead();
      verify(() => mockDio.get('notification/markallasread')).called(1);
    });
  });

  group('NotifikasiService.markAsRead', () {
    test('calls correct endpoint with ref', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse(null),
      );

      await notifikasiService.markAsRead('NOTIF-001');
      verify(() => mockDio.get('notification/markasread/NOTIF-001')).called(1);
    });
  });
}
