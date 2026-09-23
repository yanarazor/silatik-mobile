import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/providers/latik_verifikasi_provider.dart';

void main() {
  group('verifikasiActionFor (spec §8)', () {
    test('"0" Registrasi draft -> wizard', () {
      expect(verifikasiActionFor('0'), VerifikasiAction.wizard);
    });

    test('"2" Dikembalikan -> wizard (resubmit)', () {
      expect(verifikasiActionFor('2'), VerifikasiAction.wizard);
    });

    test('"8" Menunggu Pembayaran -> transaksi', () {
      expect(verifikasiActionFor('8'), VerifikasiAction.transaksi);
    });

    test('in-progress/terminal statuses -> detail', () {
      for (final s in ['1', '3', '4', '5', '6', '7']) {
        expect(verifikasiActionFor(s), VerifikasiAction.detail,
            reason: 'status $s should be detail');
      }
    });

    test('empty / unknown -> detail', () {
      expect(verifikasiActionFor(''), VerifikasiAction.detail);
      expect(verifikasiActionFor('99'), VerifikasiAction.detail);
    });

    test('trims whitespace', () {
      expect(verifikasiActionFor(' 0 '), VerifikasiAction.wizard);
    });
  });
}
