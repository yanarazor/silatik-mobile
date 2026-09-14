import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:silatik_mobile/data/models/registrasi_model.dart';
import 'package:silatik_mobile/data/repositories/auditor_repository.dart';
import 'package:silatik_mobile/data/services/auditor_payload.dart';
import 'package:silatik_mobile/providers/auditor_form_provider.dart';

class MockAuditorRepository extends Mock implements AuditorRepository {}

class FakeProfilPayload extends Fake implements AuditorProfilPayload {}

class FakeFileItem extends Fake implements FileItem {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeProfilPayload());
    registerFallbackValue(FakeFileItem());
  });

  late MockAuditorRepository repo;

  setUp(() {
    repo = MockAuditorRepository();
  });

  test('create: submitProfil calls save and captures ref', () async {
    when(() => repo.save(any())).thenAnswer((_) async => 'NEW-REF');

    final notifier = AuditorFormNotifier(repo);
    notifier.setProfil(const AuditorProfilDraft(nama: 'Budi', nik: '1'));

    await notifier.submitProfil();

    expect(notifier.state.ref, 'NEW-REF');
    expect(notifier.state.isSaved, isTrue);
    verify(() => repo.save(any())).called(1);
    verifyNever(() => repo.update(any(), any()));
  });

  test('edit: submitProfil calls update with ref, not save', () async {
    when(() => repo.update(any(), any())).thenAnswer((_) async {});

    final notifier = AuditorFormNotifier(repo);
    // Simulasi mode edit: ref sudah terisi lewat setProfil + state awal.
    notifier.setProfil(const AuditorProfilDraft(nama: 'Budi'));
    // Paksa state tersimpan dengan menandai ref lewat submit create dulu.
    when(() => repo.save(any())).thenAnswer((_) async => 'EXISTING-REF');
    await notifier.submitProfil(); // create → ref = EXISTING-REF
    clearInteractions(repo);

    await notifier.submitProfil(); // sekarang isSaved → update

    verify(() => repo.update('EXISTING-REF', any())).called(1);
    verifyNever(() => repo.save(any()));
  });

  test('payload only includes newly picked doc files (update)', () async {
    AuditorProfilPayload? captured;
    when(() => repo.update(any(), any())).thenAnswer((invocation) async {
      captured = invocation.positionalArguments[1] as AuditorProfilPayload;
    });
    when(() => repo.save(any())).thenAnswer((_) async => 'R1');

    final notifier = AuditorFormNotifier(repo);
    notifier.setProfil(const AuditorProfilDraft(nama: 'Budi'));
    await notifier.submitProfil(); // create → R1

    // Satu dokumen lama (URL server), satu baru (path lokal).
    notifier.setDoc(
        'portofolio',
        const FileItem(
            path: 'https://cdn/x.pdf', name: 'x.pdf', size: 0)); // lama
    notifier.setDoc('ktp_file',
        const FileItem(path: '/tmp/ktp.pdf', name: 'ktp.pdf', size: 5)); // baru

    await notifier.submitProfil(); // update

    expect(captured, isNotNull);
    expect(captured!.dokumen['ktp_file']?.path, '/tmp/ktp.pdf');
    expect(captured!.dokumen['portofolio']?.path, startsWith('https://'));
  });

  test('addSertifikat throws when not saved yet', () async {
    final notifier = AuditorFormNotifier(repo);
    expect(
      () => notifier.addSertifikat(
        namaPelatihan: 'X',
        tahun: '2023',
        lembaga: 'BRIN',
        sertifikatFile: const FileItem(path: '/tmp/c.pdf', name: 'c.pdf', size: 1),
      ),
      throwsStateError,
    );
  });

  test('addSertifikat posts and appends to certificates when saved', () async {
    when(() => repo.save(any())).thenAnswer((_) async => 'R1');
    when(() => repo.saveSertifikasiTeknis(
          refAuditor: any(named: 'refAuditor'),
          namaPelatihan: any(named: 'namaPelatihan'),
          tahun: any(named: 'tahun'),
          lembaga: any(named: 'lembaga'),
          sertifikatFile: any(named: 'sertifikatFile'),
        )).thenAnswer((_) async {});

    final notifier = AuditorFormNotifier(repo);
    notifier.setProfil(const AuditorProfilDraft(nama: 'Budi'));
    await notifier.submitProfil();

    await notifier.addSertifikat(
      namaPelatihan: 'Pelatihan SPBE',
      tahun: '2023',
      lembaga: 'BRIN',
      sertifikatFile: const FileItem(path: '/tmp/c.pdf', name: 'c.pdf', size: 1),
    );

    expect(notifier.state.certificates, hasLength(1));
    expect(notifier.state.certificates.first.nama, 'Pelatihan SPBE');
    verify(() => repo.saveSertifikasiTeknis(
          refAuditor: 'R1',
          namaPelatihan: 'Pelatihan SPBE',
          tahun: '2023',
          lembaga: 'BRIN',
          sertifikatFile: any(named: 'sertifikatFile'),
        )).called(1);
  });
}
