import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/data/models/latik_profile.dart';

void main() {
  group('LatikProfile.fromJson', () {
    test('reads canonical fields', () {
      final p = LatikProfile.fromJson({
        'name': 'PT Uji Latik',
        'no_pendaftaran': 'REG-001',
        'no_nib': '1234567890123',
        'no_npwp': '99.888.777.6-000.000',
        'no_str': 'STR-2025',
        'email': 'latik@test.com',
        'phone': '021555000',
        'alamat': 'Jl. Merdeka 1',
        'provinsi': 'DKI Jakarta',
        'kabupaten': 'Jakarta Pusat',
        'kode_pos': '10110',
        'str_tanggal_akhir': '2026-01-01',
      });
      expect(p.namaLatik, 'PT Uji Latik');
      expect(p.noPendaftaran, 'REG-001');
      expect(p.noNib, '1234567890123');
      expect(p.noNpwp, '99.888.777.6-000.000');
      expect(p.noStr, 'STR-2025');
      expect(p.email, 'latik@test.com');
      expect(p.strTanggalAkhir, DateTime(2026, 1, 1));
    });

    test('resolves alias key spellings', () {
      final p = LatikProfile.fromJson({
        'nama_latik_perusahaan': 'PT Alias',
        'nama_provinsi': 'Jawa Barat',
        'city_name': 'Bandung',
        'alamat_latik': 'Jl. Asia Afrika',
      });
      expect(p.namaLatik, 'PT Alias');
      expect(p.provinsi, 'Jawa Barat');
      expect(p.kabupaten, 'Bandung');
      expect(p.alamat, 'Jl. Asia Afrika');
    });

    test('reads from nested o_latik record', () {
      final p = LatikProfile.fromJson({
        'ref': 'abc',
        'o_latik': {
          'nama_latik': 'PT Nested',
          'no_pendaftaran': 'REG-N',
        },
      });
      expect(p.namaLatik, 'PT Nested');
      expect(p.noPendaftaran, 'REG-N');
    });

    test('prefers a direct field over a nested one', () {
      final p = LatikProfile.fromJson({
        'name': 'Direct',
        'o_latik': {'name': 'Nested'},
      });
      expect(p.namaLatik, 'Direct');
    });

    test('fullAddress joins present parts with postal code', () {
      final p = LatikProfile.fromJson({
        'alamat': 'Jl. A',
        'kabupaten': 'Kota B',
        'provinsi': 'Prov C',
        'kode_pos': '40111',
      });
      expect(p.fullAddress, 'Jl. A, Kota B, Prov C 40111');
    });

    test('does not fabricate a registration number when absent', () {
      final p = LatikProfile.fromJson({'name': 'PT No Reg'});
      expect(p.noPendaftaran, '');
    });

    test('isEmpty true for an empty map, false when name present', () {
      expect(LatikProfile.fromJson(const {}).isEmpty, isTrue);
      expect(LatikProfile.fromJson({'name': 'X'}).isEmpty, isFalse);
    });
  });
}
