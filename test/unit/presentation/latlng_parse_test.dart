import 'package:flutter_test/flutter_test.dart';

/// Mirror of `_LatLng.parse` from profil_lembaga_screen.dart. `_LatLng` is
/// private to the screen, so this spec pins the parse/validation rules that the
/// location card relies on. If the screen's rules change, update both.
({double lat, double lng})? parseLatLng(String rawLat, String rawLng) {
  final lat = double.tryParse(rawLat.trim());
  final lng = double.tryParse(rawLng.trim());
  if (lat == null || lng == null) return null;
  if (lat == 0 && lng == 0) return null;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
  return (lat: lat, lng: lng);
}

void main() {
  group('parseLatLng', () {
    test('parses a valid coordinate', () {
      final r = parseLatLng('-6.200000', '106.816666');
      expect(r, isNotNull);
      expect(r!.lat, -6.2);
      expect(r.lng, 106.816666);
    });

    test('trims surrounding whitespace', () {
      expect(parseLatLng('  -6.2 ', ' 106.8 '), isNotNull);
    });

    test('rejects empty or non-numeric values', () {
      expect(parseLatLng('', '106.8'), isNull);
      expect(parseLatLng('abc', '106.8'), isNull);
    });

    test('rejects the 0,0 null-island coordinate', () {
      expect(parseLatLng('0', '0'), isNull);
    });

    test('rejects out-of-range latitude or longitude', () {
      expect(parseLatLng('91', '0'), isNull);
      expect(parseLatLng('0', '181'), isNull);
      expect(parseLatLng('-90.1', '0'), isNull);
    });
  });
}
