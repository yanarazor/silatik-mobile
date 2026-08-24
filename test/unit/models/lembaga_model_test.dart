import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/data/models/lembaga_model.dart';

void main() {
  group('LembagaModel.fromJson', () {
    test('parses complete JSON', () {
      final json = {
        'nama': 'PT Teknologi Nusantara',
        'nib': '1234567890123',
        'badan_hukum': 'PT',
        'alamat': 'Jl. Gatot Subroto No. 10',
        'provinsi': 'DKI Jakarta',
        'kota': 'Jakarta Pusat',
        'kode_pos': '10270',
        'telepon': '021-1234567',
        'email': 'info@teknologi.co.id',
        'website': 'https://teknologi.co.id',
      };

      final model = LembagaModel.fromJson(json);

      expect(model.nama, 'PT Teknologi Nusantara');
      expect(model.nib, '1234567890123');
      expect(model.badanHukum, 'PT');
      expect(model.alamat, 'Jl. Gatot Subroto No. 10');
      expect(model.provinsi, 'DKI Jakarta');
      expect(model.kota, 'Jakarta Pusat');
      expect(model.kodePos, '10270');
      expect(model.telepon, '021-1234567');
      expect(model.email, 'info@teknologi.co.id');
      expect(model.website, 'https://teknologi.co.id');
    });

    test('handles missing fields with empty defaults', () {
      final json = <String, dynamic>{};
      final model = LembagaModel.fromJson(json);

      expect(model.nama, '');
      expect(model.nib, '');
      expect(model.badanHukum, '');
      expect(model.alamat, '');
      expect(model.provinsi, '');
      expect(model.kota, '');
      expect(model.kodePos, '');
      expect(model.telepon, '');
      expect(model.email, '');
      expect(model.website, '');
    });

    test('handles null values gracefully', () {
      final json = {
        'nama': null,
        'nib': null,
        'badan_hukum': null,
        'alamat': null,
        'provinsi': null,
        'kota': null,
        'kode_pos': null,
        'telepon': null,
        'email': null,
        'website': null,
      };
      final model = LembagaModel.fromJson(json);

      expect(model.nama, '');
      expect(model.nib, '');
      expect(model.badanHukum, '');
      expect(model.website, '');
    });
  });

  group('LembagaModel.toJson', () {
    test('serializes all fields', () {
      const model = LembagaModel(
        nama: 'PT Test',
        nib: '1234567890123',
        badanHukum: 'PT',
        alamat: 'Jl. Test',
        provinsi: 'Jawa Timur',
        kota: 'Surabaya',
        kodePos: '60112',
        telepon: '031-123456',
        email: 'test@test.com',
        website: 'https://test.com',
      );

      final json = model.toJson();
      expect(json['nama'], 'PT Test');
      expect(json['nib'], '1234567890123');
      expect(json['badan_hukum'], 'PT');
      expect(json['alamat'], 'Jl. Test');
      expect(json['provinsi'], 'Jawa Timur');
      expect(json['kota'], 'Surabaya');
      expect(json['kode_pos'], '60112');
      expect(json['telepon'], '031-123456');
      expect(json['email'], 'test@test.com');
      expect(json['website'], 'https://test.com');
    });

    test('website defaults to empty string', () {
      const model = LembagaModel(
        nama: 'Test',
        nib: '123',
        badanHukum: 'PT',
        alamat: '',
        provinsi: '',
        kota: '',
        kodePos: '',
        telepon: '',
        email: '',
      );
      expect(model.toJson()['website'], '');
    });
  });
}
