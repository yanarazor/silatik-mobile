import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/data/services/profile_menu_service.dart';

void main() {
  group('extractRegistrationNumber', () {
    test('returns canonical no_pendaftaran when present', () {
      final result = extractRegistrationNumber({'no_pendaftaran': 'REG-001'});
      expect(result, 'REG-001');
    });

    test('returns value from a fallback key variant', () {
      final result = extractRegistrationNumber({'nomor_registrasi': 'REG-002'});
      expect(result, 'REG-002');
    });

    test('reads from the nested o_latik record', () {
      final result = extractRegistrationNumber({
        'ref': 'abc',
        'o_latik': {'no_pendaftaran': 'REG-003'},
      });
      expect(result, 'REG-003');
    });

    test('reads from an exts list row', () {
      final result = extractRegistrationNumber({
        'exts': [
          {'unrelated': 'x'},
          {'no_pendaftaran': 'REG-004'},
        ],
      });
      expect(result, 'REG-004');
    });

    test('prefers a direct key over nested o_latik', () {
      final result = extractRegistrationNumber({
        'no_pendaftaran': 'DIRECT',
        'o_latik': {'no_pendaftaran': 'NESTED'},
      });
      expect(result, 'DIRECT');
    });

    test('returns null when no registration number is present', () {
      final result = extractRegistrationNumber({'nama': 'PT Test'});
      expect(result, isNull);
    });

    test('treats empty and literal "null" strings as absent', () {
      expect(extractRegistrationNumber({'no_pendaftaran': ''}), isNull);
      expect(extractRegistrationNumber({'no_pendaftaran': '   '}), isNull);
      expect(extractRegistrationNumber({'no_pendaftaran': 'null'}), isNull);
    });

    test('never fabricates a value for an empty map', () {
      expect(extractRegistrationNumber(const {}), isNull);
    });
  });
}
