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

  group('NotifikasiService.getPage', () {
    test('returns page from real response', () async {
      final fixture = loadFixture('notification_all.json');
      when(() => mockDio.get(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => makeResponse(fixture));

      final result = await notifikasiService.getPage();
      expect(result.items, hasLength(1));
      expect(result.page, 1);
      expect(result.totalPages, 1);
      expect(result.total, 55);
      expect(result.items.first['id'], '157c7fa5-b736-4bec-81a1-4e64f7929364');
      expect(result.items.first['data'], isA<Map>());
      verify(() => mockDio.get('notification/all',
              queryParameters: {'page': 1}))
          .called(1);
    });

    test('requests requested page and exposes pagination metadata', () async {
      when(() => mockDio.get(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => makeResponse({
                'code': 200,
                'success': true,
                'page': 2,
                'totalPages': 3,
                'total': 25,
                'data': [
                  {'id': '1'},
                ],
              }));

      final result = await notifikasiService.getPage(page: 2);
      expect(result.items, hasLength(1));
      expect(result.page, 2);
      expect(result.totalPages, 3);
      expect(result.total, 25);
      verify(() => mockDio.get('notification/all',
              queryParameters: {'page': 2}))
          .called(1);
    });

    test('returns empty page for empty response', () async {
      when(() => mockDio.get(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async =>
              makeResponse({'result': [], 'totalPages': 1}));

      final result = await notifikasiService.getPage();
      expect(result.items, isEmpty);
      expect(result.totalPages, 1);
    });
  });

  group('NotifikasiService.getUnreadPage', () {
    test('returns unread notifications from real response (no pagination metadata)', () async {
      final fixture = loadFixture('notification_unread.json');
      when(() => mockDio.get(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => makeResponse(fixture));

      final result = await notifikasiService.getUnreadPage();
      expect(result.items, hasLength(3));
      expect(result.items.first['id'], '693a984f-607c-498f-ab96-57b4404c7292');
      expect(result.items.first['data'], isA<Map>());
      expect(result.page, 1);
      expect(result.totalPages, 1);
      expect(result.total, 0);
      verify(() => mockDio.get('notification/unread',
              queryParameters: {'page': 1}))
          .called(1);
    });

    test('sends requested page param, server returns full list anyway', () async {
      when(() => mockDio.get(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => makeResponse({
                'code': 200,
                'success': true,
                'message': 'Berhasil',
                'data': [
                  {'id': '1'},
                ],
              }));

      final result = await notifikasiService.getUnreadPage(page: 2);
      expect(result.items, hasLength(1));
      expect(result.page, 1);
      expect(result.totalPages, 1);
      verify(() => mockDio.get('notification/unread',
              queryParameters: {'page': 2}))
          .called(1);
    });

    test('still honors pagination metadata when server provides it', () async {
      when(() => mockDio.get(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => makeResponse({
                'result': [
                  {'id': '1', 'judul': 'Unread 1'},
                ],
                'page': 1,
                'totalPages': 2,
                'total': 15,
              }));

      final result = await notifikasiService.getUnreadPage();
      expect(result.items, hasLength(1));
      expect(result.page, 1);
      expect(result.totalPages, 2);
      expect(result.total, 15);
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
