import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/data/services/auditor_ext_payload.dart';

void main() {
  group('buildAuditorAddCreateInvoiceFormData (penambahan, is_new=3)', () {
    test('sets is_new=3 and maps status 1->"1", else->"0"', () async {
      final form = await buildAuditorAddCreateInvoiceFormData(auditors: const [
        AuditorAddInvoiceItem(ref: 'AUD-1', nama: 'Don', status: 1),
        AuditorAddInvoiceItem(ref: 'AUD-2', nama: 'John', status: 0),
        AuditorAddInvoiceItem(ref: 'AUD-3', nama: 'Jane', status: null),
      ]);

      final fields = {for (final f in form.fields) f.key: f.value};

      expect(fields['is_new'], '3');
      expect(fields.containsKey('latik_ext'), isFalse,
          reason: 'penambahan bukan perpanjangan');

      final decoded = jsonDecode(fields['auditor']!) as Map<String, dynamic>;
      final list = (decoded['auditor'] as List).cast<Map<String, dynamic>>();

      expect(list, hasLength(3));
      expect(list[0], {
        'ref': 'AUD-1',
        'nama': 'Don',
        'status': '1',
        'is_new': '3',
      });
      expect(list[1]['status'], '0'); // status 0 -> "0"
      expect(list[2]['status'], '0'); // null -> "0"
    });
  });
}
