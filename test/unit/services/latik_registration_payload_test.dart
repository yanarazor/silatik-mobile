import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/data/services/auditor_ext_payload.dart';

void main() {
  group('buildLatikRegistrationInvoiceFormData (registration, is_new=1)', () {
    test('sets is_new=1, no latik_ext, maps status 1->"1" else "0"', () {
      final form = buildLatikRegistrationInvoiceFormData(auditors: const [
        LatikRegAuditorItem(ref: 'AUD-1', nama: 'Don', status: 1),
        LatikRegAuditorItem(ref: 'AUD-2', nama: 'John', status: 0),
        LatikRegAuditorItem(ref: 'AUD-3', nama: 'Jane', status: null),
      ]);

      final fields = {for (final f in form.fields) f.key: f.value};

      expect(fields['is_new'], '1');
      expect(fields.containsKey('latik_ext'), isFalse,
          reason: 'initial registration, not extension');

      final decoded = jsonDecode(fields['auditor']!) as Map<String, dynamic>;
      final list = (decoded['auditor'] as List).cast<Map<String, dynamic>>();

      expect(list, hasLength(3));
      expect(list[0], {
        'ref': 'AUD-1',
        'nama': 'Don',
        'status': '1',
        'is_new': '1',
      });
      expect(list[1]['status'], '0'); // Non-permanent
      expect(list[2]['status'], '0'); // null -> "0"
    });
  });

  group('latikRegistrationTotal', () {
    test('1 Permanent only -> base 5.0M (the single Permanent is free)', () {
      expect(
        latikRegistrationTotal(const [
          LatikRegAuditorItem(ref: 'A', nama: 'A', status: 1),
        ]),
        5000000,
      );
    });

    test('2 Permanent -> 6.0M (first free, second charged)', () {
      expect(
        latikRegistrationTotal(const [
          LatikRegAuditorItem(ref: 'A', nama: 'A', status: 1),
          LatikRegAuditorItem(ref: 'B', nama: 'B', status: 1),
        ]),
        6000000,
      );
    });

    test('1 Permanent + 2 Non-permanent -> 7.0M', () {
      expect(
        latikRegistrationTotal(const [
          LatikRegAuditorItem(ref: 'A', nama: 'A', status: 1),
          LatikRegAuditorItem(ref: 'B', nama: 'B', status: 0),
          LatikRegAuditorItem(ref: 'C', nama: 'C', status: 0),
        ]),
        7000000,
      );
    });

    test('0 Permanent edge -> all charged (no free slot)', () {
      expect(
        latikRegistrationTotal(const [
          LatikRegAuditorItem(ref: 'A', nama: 'A', status: 0),
          LatikRegAuditorItem(ref: 'B', nama: 'B', status: 0),
        ]),
        7000000,
      );
    });
  });
}
