import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:silatik_mobile/data/models/auditor_extension.dart';
import 'package:silatik_mobile/data/models/auditor_model.dart';
import 'package:silatik_mobile/data/models/latik_ext_model.dart';
import 'package:silatik_mobile/data/models/registrasi_model.dart';
import 'package:silatik_mobile/data/repositories/auditor_ext_repository.dart';
import 'package:silatik_mobile/data/services/auditor_ext_payload.dart';
import 'package:silatik_mobile/providers/auditor_add_revisi_provider.dart';
import 'package:silatik_mobile/providers/auditor_revisi_engine.dart';
import 'package:silatik_mobile/providers/auditor_revisi_provider.dart';

class MockAuditorExtRepository extends Mock implements AuditorExtRepository {}

AuditorModel _auditor({
  required String ref,
  required String name,
  String latikExt = 'EXT-1',
}) {
  return AuditorModel(
    id: ref,
    nama: name,
    email: '$ref@example.org',
    nik: '1234567890123456',
    tempatLahir: 'Jakarta',
    tanggalLahir: DateTime(1990, 1, 1),
    alamat: 'Jl. Test',
    provinsi: 'DKI Jakarta',
    kabupaten: 'Jakarta Selatan',
    kodePos: '12345',
    agama: 'Islam',
    phone: '08123456789',
    keterangan: '',
    fotoUrl: '',
    nomorSertifikasi: '',
    lembagaPenerbit: '',
    tanggalTerbit: null,
    tanggalBerakhir: null,
    kompetensi: const [],
    certificates: const [],
    statusLabel: 'Tetap',
    activeLabel: 'Aktif',
    verificationLabel: 'Belum',
    strTanggalAkhir: null,
    filePath: '',
    fileName: '',
    fileSize: 0,
    ktpFileUrl: '',
    sertifikatKompetensiUrl: '',
    portofolioUrl: '',
    praktikAuditUrl: '',
    asosiasiProfesiUrl: '',
    pernyataanIntegritasUrl: '',
    suratPermohonanUrl: '',
    pengangkatanUrl: '',
    auditorExt: [
      AuditorExtension(ref: 'AE-$ref', auditorRef: ref, latikExt: latikExt),
    ],
  );
}

List<ExtDokumen> _flatDocs(int count) => [
      for (var i = 0; i < count; i++)
        ExtDokumen(
          id: i,
          namaDokumen: 'Dokumen $i',
          nomorRequired: true,
          tanggalRequired: true,
          fileRequired: true,
          statusVerifikasi: i.isEven ? 2 : 1,
          catatanVerifikasi: i.isEven ? 'Perlu perbaikan' : 'Valid',
        ),
    ];

void main() {
  setUpAll(() {
    registerFallbackValue(<AuditorModel>[]);
    registerFallbackValue(<AuditorRevisiBatch>[]);
  });

  late MockAuditorExtRepository repo;

  setUp(() {
    repo = MockAuditorExtRepository();
  });

  group('AuditorExtRevisi (Renewal)', () {
    test('loads auditors, slices flat docs evenly, and builds save batches with refExt',
        () async {
      final auditors = [
        _auditor(ref: 'AUD-A', name: 'Auditor A', latikExt: 'EXT-1'),
        _auditor(ref: 'AUD-B', name: 'Auditor B', latikExt: 'EXT-1'),
      ];
      when(() => repo.getRevisiAuditorExt()).thenAnswer((_) async => auditors);
      when(() => repo.getDokumenRevisiAuditorExt(any()))
          .thenAnswer((_) async => _flatDocs(4));
      when(() => repo.saveDokumenRevisiAuditorExt(
            latikRef: any(named: 'latikRef'),
            batches: any(named: 'batches'),
          )).thenAnswer((_) async {});

      final notifier = AuditorRevisiNotifier(
        strategy: AuditorExtRevisiStrategy(repo),
        latikRef: 'LTK-1',
      );

      await notifier.load();

      expect(notifier.state.allAuditors, hasLength(2));
      expect(notifier.state.selectedIds, {'AUD-A', 'AUD-B'});
      expect(notifier.docsForAuditor(0), hasLength(2));
      expect(notifier.docsForAuditor(1), hasLength(2));

      notifier.setNomor(0, 'NOMOR-0');
      notifier.setFile(
        0,
        const FileItem(path: '/tmp/doc0.pdf', name: 'doc0.pdf', size: 1024),
      );

      expect(notifier.state.hasUnsavedEdits, true);
      await notifier.saveDokumen();
      expect(notifier.state.hasUnsavedEdits, false);

      verify(() => repo.saveDokumenRevisiAuditorExt(
            latikRef: 'LTK-1',
            batches: any(
              named: 'batches',
              that: isA<List<AuditorRevisiBatch>>()
                  .having((b) => b.first.auditorRef, 'auditorRef', 'AUD-A')
                  .having((b) => b.first.refExt, 'refExt', 'EXT-1')
                  .having((b) => b.first.dokumens.first.fileName, 'file', 'doc0.pdf'),
            ),
          )).called(1);
    });

    test('fails loud when flat docs count is not divisible by selected auditors count',
        () async {
      final auditors = [
        _auditor(ref: 'AUD-A', name: 'Auditor A'),
        _auditor(ref: 'AUD-B', name: 'Auditor B'),
      ];
      when(() => repo.getRevisiAuditorExt()).thenAnswer((_) async => auditors);
      when(() => repo.getDokumenRevisiAuditorExt(any()))
          .thenAnswer((_) async => _flatDocs(3)); // 3 % 2 != 0

      final notifier = AuditorRevisiNotifier(
        strategy: AuditorExtRevisiStrategy(repo),
        latikRef: 'LTK-1',
      );

      await notifier.load();

      expect(notifier.state.docError, isNotNull);
      expect(notifier.docsForAuditor(0), isEmpty);
    });

    test('submits revision without creating invoice', () async {
      final auditors = [_auditor(ref: 'AUD-A', name: 'Auditor A')];
      when(() => repo.getRevisiAuditorExt()).thenAnswer((_) async => auditors);
      when(() => repo.getDokumenRevisiAuditorExt(any()))
          .thenAnswer((_) async => _flatDocs(2));
      when(() => repo.requestVerifikasiRevisiAuditorExt(any()))
          .thenAnswer((_) async {});

      final notifier = AuditorRevisiNotifier(
        strategy: AuditorExtRevisiStrategy(repo),
        latikRef: 'LTK-1',
      );

      await notifier.load();
      await notifier.submit();

      verify(() => repo.requestVerifikasiRevisiAuditorExt(any())).called(1);
      verifyNever(() => repo.createInvoice(
            latikRef: any(named: 'latikRef'),
            latikExt: any(named: 'latikExt'),
            auditors: any(named: 'auditors'),
          ));
    });
  });

  group('AuditorAddRevisi (Addition)', () {
    test('builds save batches without refExt and submits via add endpoint',
        () async {
      final auditors = [_auditor(ref: 'AUD-ADD-1', name: 'Auditor Add')];
      when(() => repo.getRevisiAddAuditor()).thenAnswer((_) async => auditors);
      when(() => repo.getDokumenRevisiAddAuditor(any()))
          .thenAnswer((_) async => _flatDocs(2));
      when(() => repo.saveDokumenRevisiAddAuditor(
            latikRef: any(named: 'latikRef'),
            batches: any(named: 'batches'),
          )).thenAnswer((_) async {});
      when(() => repo.requestVerifikasiRevisiAddAuditor(any()))
          .thenAnswer((_) async {});

      final notifier = AuditorRevisiNotifier(
        strategy: AuditorAddRevisiStrategy(repo),
        latikRef: 'LTK-1',
      );

      await notifier.load();
      notifier.setFile(
        0,
        const FileItem(path: '/tmp/ktp.pdf', name: 'ktp.pdf', size: 2048),
      );
      await notifier.saveDokumen();
      await notifier.submit();

      verify(() => repo.saveDokumenRevisiAddAuditor(
            latikRef: 'LTK-1',
            batches: any(
              named: 'batches',
              that: isA<List<AuditorRevisiBatch>>().having(
                (b) => b.first.refExt,
                'refExt is null for add-auditor',
                isNull,
              ),
            ),
          )).called(1);
      verify(() => repo.requestVerifikasiRevisiAddAuditor(any())).called(1);
    });
  });
}
