import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/data/models/latik_ext_model.dart';
import 'package:silatik_mobile/providers/auditor_ext_provider.dart';

/// Bangun daftar flat ExtDokumen dengan id 0..count-1.
List<ExtDokumen> _flat(int count) => [
      for (var i = 0; i < count; i++)
        ExtDokumen(
          id: i,
          namaDokumen: 'Doc $i',
          nomorRequired: false,
          tanggalRequired: false,
          fileRequired: true,
        ),
    ];

void main() {
  group('sliceDokumenPerAuditor (positional grouping + evenness guard)', () {
    test('12 docs / 2 auditors → blocks [0,6) and [6,12)', () {
      final blocks = sliceDokumenPerAuditor(_flat(12), 2);
      expect(blocks, isNotNull);
      expect(blocks, hasLength(2));
      expect(blocks![0].map((d) => d.id), [0, 1, 2, 3, 4, 5]);
      expect(blocks[1].map((d) => d.id), [6, 7, 8, 9, 10, 11]);
    });

    test('6 docs / 1 auditor → single full block', () {
      final blocks = sliceDokumenPerAuditor(_flat(6), 1);
      expect(blocks, hasLength(1));
      expect(blocks![0].map((d) => d.id), [0, 1, 2, 3, 4, 5]);
    });

    test('5 docs / 2 auditors → null (fail loud, not divisible)', () {
      expect(sliceDokumenPerAuditor(_flat(5), 2), isNull);
    });

    test('empty list or zero auditors → null', () {
      expect(sliceDokumenPerAuditor(const [], 2), isNull);
      expect(sliceDokumenPerAuditor(_flat(6), 0), isNull);
    });
  });
}
