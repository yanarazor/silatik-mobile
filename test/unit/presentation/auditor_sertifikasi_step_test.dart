import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:silatik_mobile/data/models/auditor_model.dart';
import 'package:silatik_mobile/data/repositories/auditor_repository.dart';
import 'package:silatik_mobile/presentation/auditor/form/auditor_sertifikasi_step.dart';
import 'package:silatik_mobile/providers/auditor_form_provider.dart';

class MockAuditorRepository extends Mock implements AuditorRepository {}

Widget _host(AuditorFormNotifier notifier) {
  return ProviderScope(
    overrides: [
      auditorFormProvider(null).overrideWith((ref) => notifier),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: AuditorSertifikasiStep(
          formKey: null,
          onBack: () {},
          onFinish: () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('locked until auditor saved (no ref)', (tester) async {
    final notifier = AuditorFormNotifier(MockAuditorRepository());
    await tester.pumpWidget(_host(notifier));
    await tester.pump();

    expect(find.text('Simpan data auditor dulu'), findsOneWidget);
    expect(find.text('Tambah Sertifikat'), findsNothing);
  });

  testWidgets('unlocked and lists existing certificates once saved',
      (tester) async {
    final notifier = AuditorFormNotifier(MockAuditorRepository());
    // Buat state tersimpan lewat initFromAuditor dengan satu sertifikat.
    notifier.initFromAuditor(
      _auditorWithRef('REF-1'),
      const <AuditorDocument>[],
    );

    await tester.pumpWidget(_host(notifier));
    await tester.pump();

    expect(find.text('Tambah Sertifikat'), findsOneWidget);
    expect(find.text('Pelatihan A'), findsOneWidget);
  });
}

AuditorModel _auditorWithRef(String ref) => AuditorModel(
      id: ref,
      nama: 'Budi',
      email: '',
      nik: '3201010101010001',
      tempatLahir: '',
      tanggalLahir: null,
      alamat: '',
      provinsi: '',
      kabupaten: '',
      kodePos: '',
      agama: '',
      phone: '',
      keterangan: '',
      fotoUrl: '',
      nomorSertifikasi: '',
      lembagaPenerbit: '',
      tanggalTerbit: null,
      tanggalBerakhir: null,
      kompetensi: const [],
      certificates: const [
        AuditorCertificate(
            nama: 'Pelatihan A', lembaga: 'BRIN', tahun: '2023', fileUrl: ''),
      ],
      statusLabel: '',
      activeLabel: '',
      verificationLabel: '',
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
    );
