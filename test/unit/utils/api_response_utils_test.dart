import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/core/utils/api_response_utils.dart';

void main() {
  group('meaningfulString', () {
    test('returns trimmed value when meaningful', () {
      expect(meaningfulString('  hello '), 'hello');
      expect(meaningfulString(42), '42');
    });

    test('returns null for absent/blank/"null"', () {
      expect(meaningfulString(null), isNull);
      expect(meaningfulString(''), isNull);
      expect(meaningfulString('   '), isNull);
      expect(meaningfulString('null'), isNull);
      expect(meaningfulString('NULL'), isNull);
    });
  });

  group('pickString', () {
    test('returns first meaningful value by key order', () {
      final data = {'a': '', 'b': 'null', 'c': 'found', 'd': 'later'};
      expect(pickString(data, ['a', 'b', 'c', 'd']), 'found');
    });

    test('returns null when no key matches and no fallback', () {
      expect(pickString({'a': ''}, ['a', 'missing']), isNull);
    });

    test('returns fallback when provided and nothing matches', () {
      expect(pickString({}, ['x'], fallback: '-'), '-');
      expect(pickString({'x': 'null'}, ['x'], fallback: ''), '');
    });

    test('does not scan nested records unless deep is true', () {
      final data = {
        'o_latik': {'name': 'Nested Co'},
      };
      expect(pickString(data, ['name']), isNull);
      expect(pickString(data, ['name'], deep: true), 'Nested Co');
    });

    test('prefers a direct match over a nested one', () {
      final data = {
        'name': 'Direct',
        'o_latik': {'name': 'Nested'},
      };
      expect(pickString(data, ['name'], deep: true), 'Direct');
    });

    test('deep scan falls back to fallback when nested also empty', () {
      final data = {
        'latik': {'name': ''},
      };
      expect(pickString(data, ['name'], deep: true, fallback: '-'), '-');
    });
  });

  group('parseInt', () {
    test('passes through int and truncates num', () {
      expect(parseInt(7), 7);
      expect(parseInt(3.9), 3);
    });

    test('parses numeric strings with surrounding whitespace', () {
      expect(parseInt(' 2048 '), 2048);
    });

    test('returns null for absent/blank/"null"/unparseable', () {
      expect(parseInt(null), isNull);
      expect(parseInt(''), isNull);
      expect(parseInt('null'), isNull);
      expect(parseInt('abc'), isNull);
    });
  });

  group('parseFlexibleDate', () {
    test('parses ISO-8601', () {
      expect(parseFlexibleDate('2025-06-17'), DateTime(2025, 6, 17));
    });

    test('parses dd-mm-yyyy and dd/mm/yyyy fallback', () {
      expect(parseFlexibleDate('17-06-2025'), DateTime(2025, 6, 17));
      expect(parseFlexibleDate('5/3/2024'), DateTime(2024, 3, 5));
    });

    test('rejects out-of-range day/month in the fallback', () {
      expect(parseFlexibleDate('32-01-2024'), isNull);
      expect(parseFlexibleDate('01-13-2024'), isNull);
    });

    test('returns null for absent/blank/"null"/unrecognized', () {
      expect(parseFlexibleDate(null), isNull);
      expect(parseFlexibleDate(''), isNull);
      expect(parseFlexibleDate('null'), isNull);
      expect(parseFlexibleDate('not a date'), isNull);
    });
  });
}
