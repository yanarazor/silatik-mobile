import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:silatik_mobile/data/services/latik_service.dart';

import '../../helpers/mock_helpers.dart';

void main() {
  late MockDio mockDio;
  late LatikService latikService;

  setUp(() {
    mockDio = MockDio();
    latikService = LatikService(mockDio);
  });

  group('LatikService.getProfile', () {
    test('returns profile data', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse({
          'nama': 'PT Test',
          'nib': '1234567890123',
        }),
      );

      final result = await latikService.getProfile();
      expect(result['nama'], 'PT Test');
      verify(() => mockDio.get('latik/profile')).called(1);
    });
  });

  group('LatikService.checkNib', () {
    test('returns true when NIB is available', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => makeResponse({'available': true}),
      );

      final result = await latikService.checkNib('1234567890123');
      expect(result, isTrue);
    });

    test('returns false when NIB is not available', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => makeResponse({'available': false}),
      );

      final result = await latikService.checkNib('1234567890123');
      expect(result, isFalse);
    });

    test('returns false when available key is missing', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => makeResponse({'other': 'data'}),
      );

      final result = await latikService.checkNib('1234567890123');
      expect(result, isFalse);
    });
  });

  group('LatikService.saveLembaga', () {
    test('posts data and returns response', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => makeResponse({'ref': 'LATIK-001', 'status': 'saved'}),
      );

      final result = await latikService.saveLembaga({'nama': 'PT Test'});
      expect(result['ref'], 'LATIK-001');
      verify(() => mockDio.post('latik/save', data: {'nama': 'PT Test'}))
          .called(1);
    });
  });

  group('LatikService.getDokumen', () {
    test('returns list from real API response', () async {
      final fixture = loadFixture('latik_dokumen.json');
      when(() => mockDio.get(any())).thenAnswer((_) async =>
          makeResponse(fixture));

      final result = await latikService.getDokumen();
      expect(result, hasLength(1));
      expect(result.first['id'], 11);
      expect(result.first['nama_dokumen'], '1. Salinan akta badan hukum');
      expect(result.first['isi'], isA<Map>());
    });

    test('returns list from data key', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse({
          'data': [
            {'id': '1', 'nama': 'Doc 1'},
          ],
        }),
      );

      final result = await latikService.getDokumen();
      expect(result, hasLength(1));
    });
  });

  group('LatikService.getDokumenPendukungAktif', () {
    test('returns real active document templates', () async {
      final fixture = loadFixture('dokumen_aktif.json');
      when(() => mockDio.get(any())).thenAnswer((_) async =>
          makeResponse(fixture));

      final result = await latikService.getDokumenPendukungAktif();
      expect(result, hasLength(2));
      expect(result.first['nama_dokumen'],
          'Peraturan terkait tugas pokok dan fungsi LATIK');
      verify(() => mockDio.get('dokumen_pendukung/aktif')).called(1);
    });

    test('returns active document templates', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse({
          'data': [
            {'id': '1', 'nama': 'Template 1'},
          ],
        }),
      );

      final result = await latikService.getDokumenPendukungAktif();
      expect(result, hasLength(1));
      verify(() => mockDio.get('dokumen_pendukung/aktif')).called(1);
    });
  });

  group('LatikService.konfirmasiData', () {
    test('posts confirmation with ref', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => makeResponse(null),
      );

      await latikService.konfirmasiData('LATIK-001');
      verify(() => mockDio.post('latik/konfirmasidata',
          data: {'ref_latik': 'LATIK-001', 'is_checked': true})).called(1);
    });
  });

  group('LatikService.requestVerifikasi', () {
    test('posts verification request', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => makeResponse({'status': 'requested'}),
      );

      final result = await latikService.requestVerifikasi('LATIK-001');
      expect(result['status'], 'requested');
    });
  });

  group('LatikService.getStatusVerifikasi', () {
    test('returns verification status', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse({'status': 'verified'}),
      );

      final result = await latikService.getStatusVerifikasi();
      expect(result['status'], 'verified');
      verify(() => mockDio.get('latik/listverifikasi')).called(1);
    });
  });

  group('LatikService.getSTR', () {
    test('returns STR data', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse({
          'nomor': 'STR-2024-001',
          'tanggal_terbit': '2024-01-01',
        }),
      );

      final result = await latikService.getSTR();
      expect(result!['nomor'], 'STR-2024-001');
      verify(() => mockDio.get('latik/str_latik')).called(1);
    });
  });

  group('LatikService.getStrInvoiceList', () {
    test('returns real invoice list', () async {
      final fixture = loadFixture('latik_invoices.json');
      when(() => mockDio.get(any())).thenAnswer((_) async =>
          makeResponse(fixture));

      final result = await latikService.getStrInvoiceList();
      expect(result, hasLength(1));
      expect(result.first['ref'], '5884218f-4ea8-4766-8428-4db75ddca2fb');
      expect(result.first['kode_tagihan'], '820250605994414');
      expect(result.first['tagihan_total'], 1000000);
    });

    test('returns invoice list', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse({
          'data': [
            {'id': '1', 'amount': 100000},
          ],
        }),
      );

      final result = await latikService.getStrInvoiceList();
      expect(result, hasLength(1));
    });
  });

  group('LatikService.createInvoice', () {
    test('creates invoice with ref', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => makeResponse({'invoice_id': 'INV-001'}),
      );

      final result = await latikService.createInvoice('LATIK-001');
      expect(result['invoice_id'], 'INV-001');
    });
  });

  group('LatikService.searchLatik', () {
    test('searches with query and provinsi', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => makeResponse({
          'data': [
            {'nama': 'PT Test'},
          ],
        }),
      );

      final result =
          await latikService.searchLatik(query: 'test', provinsi: 'Jatim');
      expect(result, hasLength(1));
    });

    test('searches with only query', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => makeResponse({'data': []}),
      );

      final result = await latikService.searchLatik(query: 'test');
      expect(result, isEmpty);
    });

    test('searches with no params', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => makeResponse({'data': []}),
      );

      final result = await latikService.searchLatik();
      expect(result, isEmpty);
    });
  });

  group('LatikService.updateProfile', () {
    test('posts profile data', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => makeResponse(null),
      );

      await latikService.updateProfile({'nama': 'Updated'});
      verify(() => mockDio.post('latik/updateprofile',
          data: {'nama': 'Updated'})).called(1);
    });
  });

  group('LatikService.savePengalaman', () {
    test('posts pengalaman data', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => makeResponse(null),
      );

      await latikService.savePengalaman({'pengalaman': 'Audit 2024'});
      verify(() => mockDio.post('latik/pengalaman',
          data: {'pengalaman': 'Audit 2024'})).called(1);
    });
  });

  group('LatikService.deletePengalaman', () {
    test('deletes by ref', () async {
      when(() => mockDio.delete(any())).thenAnswer(
        (_) async => makeResponse(null),
      );

      await latikService.deletePengalaman('EXP-001');
      verify(() => mockDio.delete('latik/pengalaman/EXP-001')).called(1);
    });
  });
}
