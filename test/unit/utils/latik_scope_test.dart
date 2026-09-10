import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/presentation/profil/profil_lembaga_screen.dart';

void main() {
  group('latikScopeName', () {
    test('normalizes canonical domain names', () {
      expect(latikScopeName('aplikasi'), 'Aplikasi');
      expect(latikScopeName('infrastruktur'), 'Infrastruktur');
      expect(latikScopeName('keamanan_informasi'), 'Keamanan Informasi');
      expect(latikScopeName('Keamanan Informasi'), 'Keamanan Informasi');
      expect(latikScopeName('organisasi'), 'Organisasi');
      expect(latikScopeName('Audit Aplikasi SPBE'), 'Aplikasi');
    });

    test('returns null for empty or unknown input', () {
      expect(latikScopeName(''), isNull);
      expect(latikScopeName('null'), isNull);
      expect(latikScopeName('XYZ tidak dikenal'), isNull);
    });
  });

  group('latikScopeLabels', () {
    test('parses boolean map', () {
      expect(
        latikScopeLabels({
          'aplikasi': true,
          'infrastruktur': 1,
          'organisasi': false,
          'keamanan_informasi': 0,
        }),
        ['Aplikasi', 'Infrastruktur'],
      );
    });

    test('parses list of scope strings, dedupes and drops unknown', () {
      expect(
        latikScopeLabels(['Audit Aplikasi SPBE', 'infrastruktur', 'bukan scope']),
        ['Aplikasi', 'Infrastruktur'],
      );
    });

    test('parses comma-separated string', () {
      expect(
        latikScopeLabels('aplikasi, infrastruktur ,keamanan'),
        ['Aplikasi', 'Infrastruktur', 'Keamanan Informasi'],
      );
    });

    test('returns empty for null/empty input', () {
      expect(latikScopeLabels(null), isEmpty);
      expect(latikScopeLabels(''), isEmpty);
      expect(latikScopeLabels('null'), isEmpty);
    });
  });
}
