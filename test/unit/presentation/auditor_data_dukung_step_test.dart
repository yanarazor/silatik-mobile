import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:silatik_mobile/data/models/auditor_model.dart';
import 'package:silatik_mobile/data/models/registrasi_model.dart';
import 'package:silatik_mobile/data/repositories/auditor_repository.dart';
import 'package:silatik_mobile/data/services/auditor_payload.dart';
import 'package:silatik_mobile/presentation/auditor/form/auditor_data_dukung_step.dart';
import 'package:silatik_mobile/providers/auditor_form_provider.dart';

class MockAuditorRepository extends Mock implements AuditorRepository {}

class FakeProfilPayload extends Fake implements AuditorProfilPayload {}

const _defs = [
  AuditorDokumenDef(
      id: '1',
      namaDokumen: 'KTP',
      field: 'ktp_file',
      fileRequired: true,
      order: 1),
];

Widget _host({
  required MockAuditorRepository repo,
  required VoidCallback onSaved,
  AuditorFormNotifier? notifier,
}) {
  return ProviderScope(
    overrides: [
      auditorDokumenDefsProvider
          .overrideWith((ref) async => _defs.toList()),
      auditorFormProvider(null)
          .overrideWith((ref) => notifier ?? AuditorFormNotifier(repo)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: AuditorDataDukungStep(
          formKey: null,
          onBack: () {},
          onSaved: onSaved,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() => registerFallbackValue(FakeProfilPayload()));

  testWidgets('blocks submit and does not save when required doc missing',
      (tester) async {
    final repo = MockAuditorRepository();
    var saved = false;

    await tester.pumpWidget(_host(repo: repo, onSaved: () => saved = true));
    await tester.pump(); // resolve defs future

    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(saved, isFalse);
    verifyNever(() => repo.save(any()));
  });

  testWidgets('saves and calls onSaved when required docs present',
      (tester) async {
    final repo = MockAuditorRepository();
    when(() => repo.save(any())).thenAnswer((_) async => 'NEW-REF');
    final notifier = AuditorFormNotifier(repo);
    // Sediakan dokumen wajib lebih dulu.
    notifier.setDoc('ktp_file',
        const FileItem(path: '/tmp/ktp.pdf', name: 'ktp.pdf', size: 10));

    var saved = false;
    await tester.pumpWidget(
        _host(repo: repo, onSaved: () => saved = true, notifier: notifier));
    await tester.pump();

    await tester.tap(find.text('Simpan'));
    await tester.pump(); // submit future
    await tester.pump();

    expect(saved, isTrue);
    expect(notifier.state.ref, 'NEW-REF');
    verify(() => repo.save(any())).called(1);
  });
}
