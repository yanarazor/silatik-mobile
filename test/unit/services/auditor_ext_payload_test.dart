import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/data/services/auditor_ext_payload.dart';

Map<String, String> _fields(FormData f) =>
    {for (final e in f.fields) e.key: e.value};

void main() {
  group('buildAuditorExtSaveDokumenFormData (nested field names + d-MM-y)', () {
    test('emits auditors[i][auditor_ref] + dokumens[j][nomor|tanggal]',
        () async {
      final form = await buildAuditorExtSaveDokumenFormData(
        latikRef: 'LTK-1',
        latikExt: 'EXT-1',
        batches: [
          AuditorExtBatch(
            auditorRef: 'AUD-A',
            dokumens: [
              // id 0 (index-style dari respons flat) — file null (tak diganti).
              AuditorExtDokumenUpload(
                id: 0,
                nomor: 'ktp-123',
                tanggal: DateTime(2026, 1, 13),
              ),
            ],
          ),
          const AuditorExtBatch(
            auditorRef: 'AUD-B',
            dokumens: [
              AuditorExtDokumenUpload(id: 6, nomor: 'ktp-999'),
            ],
          ),
        ],
      );

      final f = _fields(form);
      expect(f['latik_ref'], 'LTK-1');
      expect(f['latik_ext'], 'EXT-1');
      expect(f['auditors[0][auditor_ref]'], 'AUD-A');
      expect(f['auditors[0][dokumens][0][nomor]'], 'ktp-123');
      // Tanggal d-MM-y: 13-01-2026 (bukan dd → tetap 2 digit di sini,
      // tapi format d-MM-y = "13-01-2026").
      expect(f['auditors[0][dokumens][0][tanggal]'], '13-01-2026');
      expect(f['auditors[1][auditor_ref]'], 'AUD-B');
      expect(f['auditors[1][dokumens][0][nomor]'], 'ktp-999');
      // Tak ada tanggal untuk dokumen kedua.
      expect(f.containsKey('auditors[1][dokumens][0][tanggal]'), isFalse);
    });

    test('d-MM-y drops leading zero on single-digit day', () async {
      final form = await buildAuditorExtSaveDokumenFormData(
        latikRef: 'LTK-1',
        latikExt: 'EXT-1',
        batches: [
          AuditorExtBatch(
            auditorRef: 'AUD-A',
            dokumens: [
              AuditorExtDokumenUpload(id: 0, tanggal: DateTime(2026, 3, 5)),
            ],
          ),
        ],
      );
      // d-MM-y → day tanpa leading zero: "5-03-2026".
      expect(_fields(form)['auditors[0][dokumens][0][tanggal]'], '5-03-2026');
    });
  });

  group('buildAuditorExtCreateInvoiceFormData', () {
    test('is_new=2, latik_ext/ref, auditor JSON carries ref + ref_auditor_ext',
        () async {
      final form = await buildAuditorExtCreateInvoiceFormData(
        latikRef: 'LTK-1',
        latikExt: 'EXT-1',
        auditors: const [
          AuditorExtInvoiceItem(nama: 'Don', ref: 'AUD-A'),
          AuditorExtInvoiceItem(nama: 'Mega', ref: 'AUD-B'),
        ],
      );

      final f = _fields(form);
      expect(f['is_new'], '2');
      expect(f['latik_ext'], 'EXT-1');
      expect(f['latik_ref'], 'LTK-1');

      final decoded = jsonDecode(f['auditor']!) as Map<String, dynamic>;
      final list = decoded['auditor'] as List;
      expect(list, hasLength(2));
      expect(list[0]['ref'], 'AUD-A');
      expect(list[0]['nama'], 'Don');
      expect(list[0]['is_new'], '2');
      expect(list[0]['ref_auditor_ext'], 'EXT-1');
      expect(list[0]['status'], '1');
      expect(list[1]['ref'], 'AUD-B');
    });
  });
}
