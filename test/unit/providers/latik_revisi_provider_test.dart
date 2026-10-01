import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:silatik_mobile/data/models/latik_ext_model.dart';
import 'package:silatik_mobile/data/repositories/latik_ext_repository.dart';
import 'package:silatik_mobile/data/services/latik_service.dart';
import 'package:silatik_mobile/providers/latik_revisi_provider.dart';

class MockLatikExtRepository extends Mock implements LatikExtRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(<DokumenUpload>[]);
  });

  late MockLatikExtRepository repo;
  late LatikRevisiNotifier notifier;

  setUp(() {
    repo = MockLatikExtRepository();
    notifier = LatikRevisiNotifier(repo);
  });

  test('load picks last ref_ext and parses verification status', () async {
    when(() => repo.getRevisi()).thenAnswer((_) async => [
          {'ref_ext': 'EXT-001'},
          {'ref_ext': 'EXT-002'},
        ]);
    when(() => repo.getDokumen('EXT-002')).thenAnswer((_) async => [
          const ExtDokumen(
            id: 1,
            namaDokumen: 'Surat Permohonan',
            nomorRequired: true,
            tanggalRequired: true,
            fileRequired: true,
            statusVerifikasi: 2, // Tidak Valid -> editable
            catatanVerifikasi: 'Nomor salah',
            nomor: 'DOC-1',
          ),
          const ExtDokumen(
            id: 2,
            namaDokumen: 'Struktur Organisasi',
            nomorRequired: false,
            tanggalRequired: false,
            fileRequired: true,
            statusVerifikasi: 1, // Valid -> locked
          ),
        ]);

    await notifier.load();

    expect(notifier.state.refExt, 'EXT-002');
    expect(notifier.state.dokumen.length, 2);
    expect(notifier.state.dokumen[0].def.isValid, false);
    expect(notifier.state.dokumen[1].def.isValid, true);
    expect(notifier.state.dokumen[1].def.isReadOnly, true);
  });

  test('saveDokumen sends uploads with DD-MM-YYYY format and resets edits',
      () async {
    when(() => repo.getRevisi()).thenAnswer((_) async => [
          {'ref_ext': 'EXT-001'},
        ]);
    when(() => repo.getDokumen('EXT-001')).thenAnswer((_) async => [
          const ExtDokumen(
            id: 1,
            namaDokumen: 'Surat Permohonan',
            nomorRequired: true,
            tanggalRequired: true,
            fileRequired: true,
            statusVerifikasi: 2,
          ),
        ]);
    when(() => repo.saveDokumen(
          refExt: any(named: 'refExt'),
          uploads: any(named: 'uploads'),
        )).thenAnswer((_) async {});

    await notifier.load();
    notifier.setNomor(1, 'NOMOR-BARU');
    notifier.setTanggal(1, DateTime(2026, 10, 1));
    expect(notifier.state.hasUnsavedEdits, true);

    await notifier.saveDokumen();
    expect(notifier.state.hasUnsavedEdits, false);
    verify(() => repo.saveDokumen(
          refExt: 'EXT-001',
          uploads: any(
            named: 'uploads',
            that: isA<List<DokumenUpload>>().having(
              (list) => list.first.tanggal,
              'tanggal',
              '01-10-2026',
            ),
          ),
        )).called(1);
  });

  test('submitRevisi calls requestVerifikasi directly without invoice',
      () async {
    when(() => repo.getRevisi()).thenAnswer((_) async => [
          {'ref_ext': 'EXT-001'},
        ]);
    when(() => repo.getDokumen('EXT-001')).thenAnswer((_) async => []);
    when(() => repo.requestVerifikasi('EXT-001')).thenAnswer((_) async {});

    await notifier.load();
    await notifier.submitRevisi();

    verify(() => repo.requestVerifikasi('EXT-001')).called(1);
    verifyNever(() => repo.createInvoice(any()));
  });
}
