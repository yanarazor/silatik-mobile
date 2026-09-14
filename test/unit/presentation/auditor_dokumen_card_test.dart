import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/data/models/registrasi_model.dart';
import 'package:silatik_mobile/presentation/auditor/form/auditor_dokumen_card.dart';
import 'package:silatik_mobile/providers/auditor_form_provider.dart';

Widget _host(FileItem? file, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(
        body: AuditorDokumenCard(
          title: 'KTP',
          requiredDoc: true,
          file: file,
          onPick: () {},
          onPreview: () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('empty state shows upload zone', (tester) async {
    await tester.pumpWidget(_host(null));
    await tester.pump();
    expect(find.text('Pilih Berkas'), findsOneWidget);
    expect(find.text('Pratinjau'), findsNothing);
  });

  testWidgets('local file shows its own size', (tester) async {
    await tester.pumpWidget(_host(
      const FileItem(path: '/tmp/ktp.pdf', name: 'ktp.pdf', size: 2 * 1024 * 1024),
    ));
    await tester.pump();
    expect(find.text('ktp.pdf'), findsOneWidget);
    expect(find.text('Pratinjau'), findsOneWidget);
    expect(find.text('2.00 MB'), findsOneWidget);
  });

  testWidgets('server file hides size when content-length unavailable',
      (tester) async {
    const url = 'https://cdn.example.com/ktp.pdf';
    await tester.pumpWidget(_host(
      const FileItem(path: url, name: 'ktp.pdf', size: 0),
      overrides: [
        fileContentLengthProvider(url).overrideWith((ref) async => null),
      ],
    ));
    await tester.pump();
    expect(find.text('ktp.pdf'), findsOneWidget);
    // Tidak ada teks ukuran (KB/MB) saat header tak tersedia.
    expect(find.textContaining('KB'), findsNothing);
    expect(find.textContaining('MB'), findsNothing);
  });

  testWidgets('server file shows size from content-length', (tester) async {
    const url = 'https://cdn.example.com/ktp.pdf';
    await tester.pumpWidget(_host(
      const FileItem(path: url, name: 'ktp.pdf', size: 0),
      overrides: [
        fileContentLengthProvider(url)
            .overrideWith((ref) async => 2 * 1024 * 1024),
      ],
    ));
    await tester.pump(); // resolve future
    expect(find.text('2.00 MB'), findsOneWidget);
  });
}
