import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:silatik_mobile/data/models/auditor_document.dart';
import 'package:silatik_mobile/data/models/auditor_model.dart';
import 'package:silatik_mobile/data/models/master_data_model.dart';
import 'package:silatik_mobile/data/repositories/auditor_repository.dart';
import 'package:silatik_mobile/presentation/auditor/form/auditor_profil_step.dart';
import 'package:silatik_mobile/providers/auditor_form_provider.dart';
import 'package:silatik_mobile/providers/master_data_provider.dart';

class MockAuditorRepository extends Mock implements AuditorRepository {}

/// Override yang menghindari graph dio/env asli: master data kosong + form
/// notifier pakai repo mock.
List<Override> _overrides(MockAuditorRepository repo) => [
      provinsiListProvider.overrideWith((ref) async => <ProvinsiModel>[]),
      agamaListProvider.overrideWith((ref) async => <AgamaModel>[]),
      auditorFormProvider(null).overrideWith((ref) => AuditorFormNotifier(repo)),
    ];

Widget _host({required VoidCallback onNext, required MockAuditorRepository repo}) {
  return ProviderScope(
    overrides: _overrides(repo),
    child: MaterialApp(
      home: Scaffold(
        body: AuditorProfilStep(formKey: null, onNext: onNext),
      ),
    ),
  );
}

void main() {
  testWidgets('blocks onNext when NIK invalid', (tester) async {
    var advanced = false;
    await tester
        .pumpWidget(_host(onNext: () => advanced = true, repo: MockAuditorRepository()));
    await tester.pump();

    // Tap Selanjutnya tanpa isi apa pun.
    await tester.scrollUntilVisible(find.text('Selanjutnya'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();

    expect(advanced, isFalse);
  });

  testWidgets(
      'valid text fields but no photo/date still blocks and does not write draft',
      (tester) async {
    var advanced = false;
    late WidgetRef capturedRef;
    final repo = MockAuditorRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(repo),
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return AuditorProfilStep(
                    formKey: null, onNext: () => advanced = true);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Isi semua field teks wajib (tapi tanggal lahir & foto tetap kosong,
    // karena picker butuh platform channel yang tak tersedia di test).
    final form =
        tester.widget<ReactiveForm>(find.byType(ReactiveForm)).formGroup;
    form.control('nama').value = 'John Doe';
    form.control('nik').value = '3201010101010001';
    form.control('email').value = 'john@example.com';
    form.control('tempat_lahir').value = 'Jakarta';
    await tester.pump();

    await tester.scrollUntilVisible(find.text('Selanjutnya'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();

    // Tanggal lahir & foto wajib → tetap terblokir, draft tak ditulis.
    expect(advanced, isFalse);
    expect(capturedRef.read(auditorFormProvider(null)).profil.nama, isEmpty);
  });

  testWidgets('edit mode prefills form from notifier draft', (tester) async {
    const ref = 'REF-1';
    final notifier = AuditorFormNotifier(MockAuditorRepository());
    // Simulasikan initFromAuditor yang dipanggil layar saat edit.
    notifier.initFromAuditor(_auditor(ref), const <AuditorDocument>[]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          provinsiListProvider.overrideWith((ref) async => <ProvinsiModel>[]),
          agamaListProvider.overrideWith((ref) async => <AgamaModel>[]),
          auditorFormProvider(ref).overrideWith((_) => notifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AuditorProfilStep(formKey: ref, onNext: _noop),
          ),
        ),
      ),
    );
    await tester.pump();

    final form =
        tester.widget<ReactiveForm>(find.byType(ReactiveForm)).formGroup;
    expect(form.control('nama').value, 'Budi Santoso');
    expect(form.control('nik').value, '3201010101010001');
    expect(form.control('email').value, 'budi@example.com');
    expect(find.text('Budi Santoso'), findsWidgets);
  });

  testWidgets('edit mode prefills kabupaten once its list loads',
      (tester) async {
    const ref = 'REF-2';
    final notifier = AuditorFormNotifier(MockAuditorRepository());
    notifier.initFromAuditor(
      _auditorWithWilayah(ref, provinsi: '32', kabupaten: '3216'),
      const <AuditorDocument>[],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          provinsiListProvider.overrideWith(
              (ref) async => [ProvinsiModel(id: '32', nama: 'Jawa Barat')]),
          kabupatenListProvider('32').overrideWith((ref) async =>
              [KabupatenModel(id: '3216', nama: 'Kab. Bekasi', provinsiId: '32')]),
          agamaListProvider.overrideWith((ref) async => <AgamaModel>[]),
          auditorFormProvider(ref).overrideWith((_) => notifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AuditorProfilStep(formKey: ref, onNext: _noop),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final form =
        tester.widget<ReactiveForm>(find.byType(ReactiveForm)).formGroup;
    expect(form.control('provinsi').value, '32');
    expect(form.control('kabupaten').value, '3216');
  });
}

void _noop() {}

AuditorModel _auditor(String ref) => _auditorWithWilayah(ref);

AuditorModel _auditorWithWilayah(
  String ref, {
  String provinsi = '',
  String kabupaten = '',
}) =>
    AuditorModel(
      id: ref,
      nama: 'Budi Santoso',
      email: 'budi@example.com',
      nik: '3201010101010001',
      tempatLahir: 'Jakarta',
      tanggalLahir: DateTime(1990, 5, 21),
      alamat: '',
      provinsi: provinsi,
      kabupaten: kabupaten,
      kodePos: '',
      agama: '',
      phone: '08123456789',
      keterangan: '',
      fotoUrl: 'https://cdn.example.com/foto.jpg',
      nomorSertifikasi: '',
      lembagaPenerbit: '',
      tanggalTerbit: null,
      tanggalBerakhir: null,
      kompetensi: const [],
      certificates: const [],
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
