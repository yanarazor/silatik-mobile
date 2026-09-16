import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/presentation/profil/latik_profile_payload.dart';

/// Pins the /latik/saveprofile contract: key names, numeric province/kabupaten
/// ids, 0/1 scope flags, and coordinate duplication (position + flat lat/lng).
void main() {
  group('buildSaveProfilePayload', () {
    final payload = buildSaveProfilePayload(
      ref: 'REF123',
      noPendaftaran: '3CIMYM6TLLJG1',
      namaLatik: 'Testing DS Silatik',
      email: 'user@example.com',
      address: 'Jalan testing no.17',
      phone: '089111222333',
      website: 'www.google.com',
      noNib: '1234567891011',
      noNpwp: '880123456789',
      noStr: '005-.L-SPBE.BRIN.2025',
      areaOperasional: 'Thamrin',
      provinsiId: '31',
      kabupatenId: '3173',
      scopeAplikasi: true,
      scopeInfrastruktur: true,
      latitude: '48.8584607',
      longitude: '2.2940691',
    );

    test('sends numeric province/kabupaten ids', () {
      expect(payload['provinsi'], 31);
      expect(payload['kabupaten'], 3173);
    });

    test('scope flags are integers 0/1', () {
      expect(payload['lingkup_pendaftaran'],
          {'aplikasi': 1, 'infrastruktur': 1});
    });

    test('scope maps false -> 0', () {
      final p = buildSaveProfilePayload(
        ref: '',
        noPendaftaran: 'X',
        namaLatik: 'n',
        email: 'e',
        address: 'a',
        phone: '1',
        website: 'w',
        noNib: '1',
        noNpwp: '1',
        noStr: 's',
        areaOperasional: '',
        provinsiId: '1',
        kabupatenId: '2',
        scopeAplikasi: true,
        scopeInfrastruktur: false,
        latitude: '1',
        longitude: '2',
      );
      expect(p['lingkup_pendaftaran'], {'aplikasi': 1, 'infrastruktur': 0});
      // ref omitted when empty
      expect(p.containsKey('ref'), isFalse);
    });

    test('duplicates coordinates flat and nested, as strings', () {
      expect(payload['latitude'], '48.8584607');
      expect(payload['longitude'], '2.2940691');
      expect(payload['position'], {'lat': '48.8584607', 'lng': '2.2940691'});
    });

    test('carries empty no_siup / jml_auditor', () {
      expect(payload['no_siup'], '');
      expect(payload['jml_auditor'], '');
    });

    test('includes ref when present and expected keys', () {
      expect(payload['ref'], 'REF123');
      expect(payload['nama_latik'], 'Testing DS Silatik');
      expect(payload['no_nib'], '1234567891011');
      expect(payload['no_npwp'], '880123456789');
    });

    test('non-numeric province id falls back to raw string', () {
      final p = buildSaveProfilePayload(
        ref: '',
        noPendaftaran: 'X',
        namaLatik: 'n',
        email: 'e',
        address: 'a',
        phone: '1',
        website: 'w',
        noNib: '1',
        noNpwp: '1',
        noStr: 's',
        areaOperasional: '',
        provinsiId: '',
        kabupatenId: '',
        scopeAplikasi: true,
        scopeInfrastruktur: true,
        latitude: '1',
        longitude: '2',
      );
      expect(p['provinsi'], '');
      expect(p['kabupaten'], '');
    });
  });

  group('generateNoPendaftaran', () {
    test('is 13 uppercase alphanumeric chars', () {
      final id = generateNoPendaftaran();
      expect(id.length, 13);
      expect(RegExp(r'^[A-Z0-9]{13}$').hasMatch(id), isTrue);
    });
  });
}
