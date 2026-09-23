import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:silatik_mobile/data/models/auditor_model.dart';
import 'package:silatik_mobile/data/repositories/latik_verifikasi_repository.dart';
import 'package:silatik_mobile/data/services/auditor_ext_payload.dart';
import 'package:silatik_mobile/data/services/latik_service.dart';
import 'package:silatik_mobile/providers/latik_verifikasi_provider.dart';

class MockRepo extends Mock implements LatikVerifikasiRepository {}

AuditorModel auditor(String ref, int status) =>
    AuditorModel.fromJson({'ref': ref, 'nama': ref, 'status': status});

void main() {
  setUpAll(() {
    registerFallbackValue(<DokumenUpload>[]);
    registerFallbackValue(<LatikRegAuditorItem>[]);
  });

  late MockRepo repo;
  setUp(() => repo = MockRepo());

  group('gate (§3)', () {
    test('empty selection -> gate fails', () {
      final n = LatikVerifikasiNotifier(repo, 'LTK-1');
      expect(n.state.gatePassed, isFalse);
    });

    test('selection without Tetap -> gate fails', () {
      final n = LatikVerifikasiNotifier(repo, 'LTK-1');
      n.toggle(auditor('A', 0), true);
      expect(n.state.hasSelection, isTrue);
      expect(n.state.hasTetap, isFalse);
      expect(n.state.gatePassed, isFalse);
    });

    test('selection with >=1 Tetap -> gate passes', () {
      final n = LatikVerifikasiNotifier(repo, 'LTK-1');
      n.toggle(auditor('A', 0), true);
      n.toggle(auditor('B', 1), true);
      expect(n.state.gatePassed, isTrue);
    });

    test('toggle off removes selection', () {
      final n = LatikVerifikasiNotifier(repo, 'LTK-1');
      final a = auditor('A', 1);
      n.toggle(a, true);
      expect(n.isSelected(a), isTrue);
      n.toggle(a, false);
      expect(n.isSelected(a), isFalse);
    });
  });

  group('submit Branch A (status "2" rejected)', () {
    test('calls requestVerifikasi only, no invoice/confirm/billing', () async {
      when(() => repo.requestVerifikasi(any())).thenAnswer((_) async {});
      final n = LatikVerifikasiNotifier(repo, 'LTK-1');
      n.toggle(auditor('A', 1), true);

      final ref = await n.submit(status: '2', uploads: const []);

      expect(ref, '');
      verify(() => repo.requestVerifikasi('LTK-1')).called(1);
      verifyNever(() => repo.saveDokumen(any()));
      verifyNever(() => repo.createInvoice(any()));
      verifyNever(() => repo.konfirmasiData());
    });
  });

  group('submit Branch B (status "0" first-time)', () {
    test('saveDokumen -> createInvoice -> konfirmasiData -> billing, returns ref',
        () async {
      when(() => repo.saveDokumen(any())).thenAnswer((_) async {});
      when(() => repo.createInvoice(any())).thenAnswer((_) async => 'INV-9');
      when(() => repo.konfirmasiData()).thenAnswer((_) async {});
      when(() => repo.billing(any(), refLatik: any(named: 'refLatik')))
          .thenAnswer((_) async => 'KODE-1');
      when(() => repo.checkBilling(any())).thenAnswer((_) async => {});

      final n = LatikVerifikasiNotifier(repo, 'LTK-1');
      n.toggle(auditor('A', 1), true);

      final ref = await n.submit(status: '0', uploads: const []);

      expect(ref, 'INV-9');
      verifyInOrder([
        () => repo.saveDokumen(any()),
        () => repo.createInvoice(any()),
        () => repo.konfirmasiData(),
        () => repo.billing('INV-9', refLatik: 'LTK-1'),
        () => repo.checkBilling('KODE-1'),
      ]);
      verifyNever(() => repo.requestVerifikasi(any()));
    });

    test('billing failure does not fail the submit (best-effort)', () async {
      when(() => repo.saveDokumen(any())).thenAnswer((_) async {});
      when(() => repo.createInvoice(any())).thenAnswer((_) async => 'INV-9');
      when(() => repo.konfirmasiData()).thenAnswer((_) async {});
      when(() => repo.billing(any(), refLatik: any(named: 'refLatik')))
          .thenThrow(Exception('billing down'));

      final n = LatikVerifikasiNotifier(repo, 'LTK-1');
      n.toggle(auditor('A', 1), true);

      final ref = await n.submit(status: '0', uploads: const []);
      expect(ref, 'INV-9');
      expect(n.state.submitting, isFalse);
    });
  });
}
