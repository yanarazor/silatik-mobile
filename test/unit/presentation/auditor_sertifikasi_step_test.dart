import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:silatik_mobile/data/models/auditor_model.dart';
import 'package:silatik_mobile/data/repositories/auditor_repository.dart';
import 'package:silatik_mobile/presentation/auditor/form/auditor_sertifikasi_body.dart';
import 'package:silatik_mobile/presentation/shared/dokumen_upload_card.dart';
import 'package:silatik_mobile/providers/auditor_form_provider.dart';
import 'package:silatik_mobile/providers/auditor_provider.dart';

class MockAuditorRepository extends Mock implements AuditorRepository {}

const _ref = 'AUD-1';

Widget _host(AuditorFormNotifier notifier, List<AuditorCertificate> certs) {
  return ProviderScope(
    overrides: [
      auditorFormProvider(_ref).overrideWith((ref) => notifier),
      auditorSertifikasiProvider(_ref).overrideWith((ref) async => certs),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: AuditorSertifikasiBody(formKey: _ref),
      ),
    ),
  );
}

void main() {
  testWidgets('shows add form', (tester) async {
    final notifier = AuditorFormNotifier(MockAuditorRepository());
    await tester.pumpWidget(_host(notifier, const []));
    await tester.pumpAndSettle();

    // List-first: tombol Tambah Sertifikat tampil; form ada di bottom sheet.
    expect(find.text('Tambah Sertifikat'), findsOneWidget);
    expect(find.byType(DokumenUploadCard), findsNothing);
  });

  testWidgets('empty state shown when no certificates', (tester) async {
    final notifier = AuditorFormNotifier(MockAuditorRepository());
    await tester.pumpWidget(_host(notifier, const []));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada sertifikat'), findsOneWidget);
  });

  testWidgets('lists saved certificates from server provider', (tester) async {
    final notifier = AuditorFormNotifier(MockAuditorRepository());
    await tester.pumpWidget(_host(notifier, const [
      AuditorCertificate(
          ref: 'C1', nama: 'Pelatihan A', lembaga: 'BRIN', tahun: '2023', fileUrl: ''),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Pelatihan A'), findsOneWidget);
    expect(find.text('Sertifikat Tersimpan (1)'), findsOneWidget);
    // Sertifikat dengan ref bisa dihapus → ada tombol hapus.
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });
}
