import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:silatik_mobile/data/services/latik_service.dart';

import '../../helpers/mock_helpers.dart';

/// Menyaring FormData.fields menjadi Map<key,value> untuk verifikasi mudah.
Map<String, String> _fields(FormData f) =>
    {for (final e in f.fields) e.key: e.value};

void main() {
  late MockDio mockDio;
  late LatikService service;

  setUp(() {
    mockDio = MockDio();
    service = LatikService(mockDio);
    registerFallbackValue(FormData());
  });

  group('LatikService.saveExtDokumen (multipart field names + date)', () {
    test('emits ref_ext + nomor_{id}/tanggal_{id} with caller-formatted date',
        () async {
      FormData? sent;
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((invocation) async {
        sent = invocation.namedArguments[#data] as FormData;
        return makeResponse<Map<String, dynamic>>({'success': true});
      });

      await service.saveExtDokumen(
        refExt: 'REF-EXT-1',
        uploads: const [
          // Berkas tak diganti → file null → dikirim "undefined".
          DokumenUpload(id: 1, nomor: 'no-akreditasi', tanggal: '13-01-2026'),
          // Dokumen tanpa tanggal → key tanggal_ tidak dikirim.
          DokumenUpload(id: 3, nomor: ''),
        ],
      );

      final f = _fields(sent!);
      expect(f['ref_ext'], 'REF-EXT-1');
      expect(f['nomor_1'], 'no-akreditasi');
      // Tanggal diteruskan apa adanya (sudah DD-MM-YYYY dari pemanggil).
      expect(f['tanggal_1'], '13-01-2026');
      expect(f['file_1'], 'undefined');
      expect(f['nomor_3'], '');
      // Tak ada tanggal untuk id 3.
      expect(f.containsKey('tanggal_3'), isFalse);
    });
  });

  group('LatikService.createExtInvoice', () {
    test('sends is_new=2, empty auditor list, latik_ext and returns data.ref',
        () async {
      FormData? sent;
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((invocation) async {
        sent = invocation.namedArguments[#data] as FormData;
        return makeResponse<Map<String, dynamic>>({
          'success': true,
          'data': {'ref': 'INV-abc123'},
        });
      });

      final ref = await service.createExtInvoice('REF-EXT-1');

      final f = _fields(sent!);
      expect(f['is_new'], '2');
      expect(f['auditor'], '{"auditor":[]}');
      expect(f['latik_ext'], 'REF-EXT-1');
      expect(ref, 'INV-abc123');
    });
  });

  group('LatikService.getBilling', () {
    test('extracts kode_tagihan from data envelope', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => makeResponse<Map<String, dynamic>>({
                'success': true,
                'data': {'kode_tagihan': '1234567890123456'},
              }));

      final kode = await service.getBilling('INV-abc123');
      expect(kode, '1234567890123456');
    });
  });
}
