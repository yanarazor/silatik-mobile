import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:silatik_mobile/core/constants/api_endpoints.dart';
import 'package:silatik_mobile/data/services/auditor_service.dart';

import '../../helpers/mock_helpers.dart';

void main() {
  late MockDio dio;
  late AuditorService service;

  setUp(() {
    dio = MockDio();
    service = AuditorService(dio);
  });

  test('gets auditor extension revisions from endpoint', () async {
    when(() => dio.get(ApiEndpoints.auditorExtRevision)).thenAnswer(
      (_) async => makeResponse({
        'data': [
          {'ref': 'AUD-1', 'nama': 'Auditor One'},
        ],
      }),
    );

    final result = await service.getRevisiAuditorExt();

    expect(result.single['ref'], 'AUD-1');
    verify(() => dio.get(ApiEndpoints.auditorExtRevision)).called(1);
  });

  test('gets add-auditor revisions from endpoint', () async {
    when(() => dio.get(ApiEndpoints.auditorAddRevision)).thenAnswer(
      (_) async => makeResponse({
        'data': [
          {'ref': 'AUD-2', 'nama': 'Auditor Two'},
        ],
      }),
    );

    final result = await service.getRevisiAddAuditor();

    expect(result.single['ref'], 'AUD-2');
    verify(() => dio.get(ApiEndpoints.auditorAddRevision)).called(1);
  });

  test('loads extension revision documents with ref pairs', () async {
    final body = [
      {'ref_ext': 'EXT-1', 'ref_auditor': 'AUD-1'},
    ];
    when(() => dio.post(ApiEndpoints.auditorExtRevisiGetDokumen, data: body))
        .thenAnswer((_) async => makeResponse({
              'data': [
                {
                  'id': 0,
                  'nama_dokumen': 'Sertifikat',
                  'nomor_required': 1,
                  'tanggal_required': 1,
                  'file_required': 1,
                  'isi': {
                    'status_verifikasi': 2,
                    'catatan_verifikasi': 'Perbarui sertifikat',
                    'url_dokumen': 'https://example.invalid/a.pdf',
                  },
                },
              ],
            }));

    final result = await service.getDokumenRevisiAuditorExt(body);

    expect(result.single['nama_dokumen'], 'Sertifikat');
    verify(() =>
        dio.post(ApiEndpoints.auditorExtRevisiGetDokumen, data: body)).called(1);
  });

  test('loads add-auditor revision documents with auditor refs', () async {
    final body = [
      {'ref_auditor': 'AUD-1'},
    ];
    when(() => dio.post(ApiEndpoints.auditorAddRevisiGetDokumen, data: body))
        .thenAnswer((_) async => makeResponse({
              'data': [
                {'id': 0, 'nama_dokumen': 'KTP'},
              ],
            }));

    final result = await service.getDokumenRevisiAddAuditor(body);

    expect(result.single['nama_dokumen'], 'KTP');
    verify(() =>
        dio.post(ApiEndpoints.auditorAddRevisiGetDokumen, data: body)).called(1);
  });

  test('resubmits auditor extension and add-auditor selections', () async {
    final extBody = [
      {'ref_ext': 'EXT-1', 'ref_auditor': 'AUD-1'},
    ];
    final addBody = [
      {'ref_auditor': 'AUD-2'},
    ];
    when(() => dio.post(ApiEndpoints.auditorExtRequestRevision, data: extBody))
        .thenAnswer((_) async => makeResponse({'success': true}));
    when(() => dio.post(ApiEndpoints.auditorAddRequestRevision, data: addBody))
        .thenAnswer((_) async => makeResponse({'success': true}));

    await service.requestVerifikasiRevisiAuditorExt(extBody);
    await service.requestVerifikasiRevisiAddAuditor(addBody);

    verify(() =>
        dio.post(ApiEndpoints.auditorExtRequestRevision, data: extBody)).called(1);
    verify(() =>
        dio.post(ApiEndpoints.auditorAddRequestRevision, data: addBody)).called(1);
  });
}
