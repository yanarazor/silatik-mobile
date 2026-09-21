import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/data/models/latik_ext_model.dart';

void main() {
  group('ExtResolution.fromResponse', () {
    // Envelope nyata dari POST /latikext (dipangkas ke field yang dipakai).
    Map<String, dynamic> envelope(int status) => {
          'code': 200,
          'success': true,
          'data': [
            {
              'id': 88,
              'ref_ext': '84604be1-3d99-4759-85fe-750f59794f7f',
              'ref_latik': '3d1bf16c',
              'status': status,
              'no_str': '005-.L-SPBE.BRIN.2025',
            }
          ],
        };

    test('parses ref_ext, status, no_str from first record', () {
      final r = ExtResolution.fromResponse(envelope(0));
      expect(r, isNotNull);
      expect(r!.refExt, '84604be1-3d99-4759-85fe-750f59794f7f');
      expect(r.status, 0);
      expect(r.noStr, '005-.L-SPBE.BRIN.2025');
    });

    test('status maps to the correct action', () {
      expect(ExtResolution.fromResponse(envelope(0))!.action, ExtAction.proceed);
      expect(ExtResolution.fromResponse(envelope(1))!.action,
          ExtAction.inVerification);
      expect(
          ExtResolution.fromResponse(envelope(2))!.action, ExtAction.returned);
      expect(ExtResolution.fromResponse(envelope(3))!.action,
          ExtAction.publishingStr);
      // Nilai tak dikenal → aman ke proceed (bukan blokir tanpa alasan).
      expect(ExtResolution.fromResponse(envelope(9))!.action, ExtAction.proceed);
    });

    test('returns null when data list is empty or malformed', () {
      expect(ExtResolution.fromResponse({'data': []}), isNull);
      expect(ExtResolution.fromResponse({'data': <dynamic>[]}), isNull);
      // ref_ext hilang → tak bisa lanjut, kembalikan null.
      expect(
        ExtResolution.fromResponse({
          'data': [
            {'status': 0}
          ]
        }),
        isNull,
      );
    });
  });

  group('ExtDokumen.fromJson', () {
    // Satu record nyata dari GET /latikext/dokumen/view (dipangkas).
    Map<String, dynamic> doc({
      required int id,
      required int nomorReq,
      required int tanggalReq,
      required int fileReq,
      String? nomor,
      String? tanggal,
      String? url,
    }) =>
        {
          'id': id,
          'nama_dokumen': 'Sertifikat akreditasi KAN aktif',
          'nomor_required': nomorReq,
          'tanggal_required': tanggalReq,
          'file_required': fileReq,
          'isi': {
            'nomor': nomor,
            'tanggal': tanggal,
            'url_dokumen': url,
          },
        };

    test('reads required flags (1 = wajib, 0 = tidak)', () {
      final d = ExtDokumen.fromJson(
          doc(id: 1, nomorReq: 1, tanggalReq: 1, fileReq: 1));
      expect(d.id, 1);
      expect(d.namaDokumen, 'Sertifikat akreditasi KAN aktif');
      expect(d.nomorRequired, isTrue);
      expect(d.tanggalRequired, isTrue);
      expect(d.fileRequired, isTrue);

      final optional = ExtDokumen.fromJson(
          doc(id: 4, nomorReq: 0, tanggalReq: 0, fileReq: 0));
      expect(optional.nomorRequired, isFalse);
      expect(optional.tanggalRequired, isFalse);
      expect(optional.fileRequired, isFalse);
    });

    test('prefills nomor/tanggal/url from nested isi', () {
      final d = ExtDokumen.fromJson(doc(
        id: 1,
        nomorReq: 1,
        tanggalReq: 1,
        fileReq: 1,
        nomor: 'no-sert-akreditasi',
        tanggal: '2026-01-13',
        url: 'https://cdn/x.pdf',
      ));
      expect(d.nomor, 'no-sert-akreditasi');
      expect(d.tanggal, '2026-01-13');
      expect(d.fileUrl, 'https://cdn/x.pdf');
    });

    test('leaves prefill empty when isi values are null', () {
      final d = ExtDokumen.fromJson(
          doc(id: 3, nomorReq: 0, tanggalReq: 0, fileReq: 1));
      expect(d.nomor, isEmpty);
      expect(d.tanggal, isEmpty);
      expect(d.fileUrl, isEmpty);
    });
  });
}
