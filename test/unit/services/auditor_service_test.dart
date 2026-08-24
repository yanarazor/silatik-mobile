import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:silatik_mobile/data/services/auditor_service.dart';

import '../../helpers/mock_helpers.dart';

void main() {
  late MockDio mockDio;
  late AuditorService auditorService;

  setUp(() {
    mockDio = MockDio();
    auditorService = AuditorService(mockDio);
  });

  group('AuditorService.getAuditorsByLatik', () {
    test('returns list from real API response', () async {
      final fixture = loadFixture('latik_auditors.json');
      when(() => mockDio.get(any())).thenAnswer((_) async =>
          makeResponse(fixture));

      final result = await auditorService.getAuditorsByLatik();
      expect(result, hasLength(1));
      expect(result.first['ref'], '2f19d2af-bf7b-43a2-aa9d-829fd7680483');
      expect(result.first['nama'], 'Mega Puspitasari');
      expect(result.first['status_aktif'], 1);
    });

    test('returns list from direct array response', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse([
          {'ref': 'A1', 'nama': 'Auditor 1'},
          {'ref': 'A2', 'nama': 'Auditor 2'},
        ]),
      );

      final result = await auditorService.getAuditorsByLatik();
      expect(result, hasLength(2));
      expect(result.first['nama'], 'Auditor 1');
    });

    test('returns list from nested result.data response', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse({
          'result': {
            'data': [
              {'ref': 'A1', 'nama': 'Auditor 1'},
            ],
          },
        }),
      );

      final result = await auditorService.getAuditorsByLatik();
      expect(result, hasLength(1));
    });

    test('returns list from result.items response', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse({
          'result': {
            'items': [
              {'ref': 'A1'},
            ],
          },
        }),
      );

      final result = await auditorService.getAuditorsByLatik();
      expect(result, hasLength(1));
    });

    test('returns list from data.items response', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse({
          'items': [
            {'ref': 'A1'},
          ],
        }),
      );

      final result = await auditorService.getAuditorsByLatik();
      expect(result, hasLength(1));
    });

    test('returns empty list for unrecognized response', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse({'unexpected': 'format'}),
      );

      final result = await auditorService.getAuditorsByLatik();
      expect(result, isEmpty);
    });

    test('returns empty list for null data', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse(null),
      );

      final result = await auditorService.getAuditorsByLatik();
      expect(result, isEmpty);
    });
  });

  group('AuditorService.getAuditorDetail', () {
    test('returns auditor map', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse({
          'ref': 'A1',
          'nama': 'Budi',
          'email': 'budi@test.com',
        }),
      );

      final result = await auditorService.getAuditorDetail('A1');
      expect(result['nama'], 'Budi');
      verify(() => mockDio.get('latik/auditor/view/A1')).called(1);
    });
  });

  group('AuditorService.saveAuditor', () {
    test('posts data and returns response', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => makeResponse({'ref': 'A1', 'status': 'saved'}),
      );

      final result = await auditorService.saveAuditor({'nama': 'Budi'});
      expect(result['status'], 'saved');
      verify(() => mockDio.post('auditor/save', data: {'nama': 'Budi'}))
          .called(1);
    });
  });

  group('AuditorService.updateAuditor', () {
    test('posts update data', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => makeResponse(null),
      );

      await auditorService.updateAuditor({'ref': 'A1', 'nama': 'Updated'});
      verify(() => mockDio.post('auditor/update',
          data: {'ref': 'A1', 'nama': 'Updated'})).called(1);
    });
  });

  group('AuditorService.deleteAuditor', () {
    test('deletes by ref', () async {
      when(() => mockDio.delete(any())).thenAnswer(
        (_) async => makeResponse(null),
      );

      await auditorService.deleteAuditor('A1');
      verify(() => mockDio.delete('auditor/A1')).called(1);
    });
  });

  group('AuditorService.simpanSertifikasiTeknis', () {
    test('posts certification data', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => makeResponse(null),
      );

      await auditorService
          .simpanSertifikasiTeknis({'ref_auditor': 'A1', 'nama': 'Cert'});
      verify(() => mockDio.post('auditor/simpansertifikasiteknis',
          data: {'ref_auditor': 'A1', 'nama': 'Cert'})).called(1);
    });
  });

  group('AuditorService.deleteSertifikasiTeknis', () {
    test('deletes by ref', () async {
      when(() => mockDio.delete(any())).thenAnswer(
        (_) async => makeResponse(null),
      );

      await auditorService.deleteSertifikasiTeknis('CERT-001');
      verify(() => mockDio.delete('auditor/sertifikasiteknis/CERT-001'))
          .called(1);
    });
  });

  group('AuditorService.requestVerifikasiPenambahan', () {
    test('posts ref_latik', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => makeResponse(null),
      );

      await auditorService.requestVerifikasiPenambahan('LATIK-001');
      verify(() => mockDio.post('auditor/penambahan/requestverifikasi',
          data: {'ref_latik': 'LATIK-001'})).called(1);
    });
  });
}
