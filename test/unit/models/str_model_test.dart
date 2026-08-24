import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/data/models/str_model.dart';

void main() {
  group('StrModel.fromJson', () {
    test('parses complete JSON', () {
      final json = {
        'nomor': 'STR-2024-001',
        'tanggal_terbit': '2024-01-15',
        'berlaku_hingga': '2027-01-15',
      };

      final model = StrModel.fromJson(json);

      expect(model.nomor, 'STR-2024-001');
      expect(model.tanggalTerbit, DateTime(2024, 1, 15));
      expect(model.berlakuHingga, DateTime(2027, 1, 15));
    });

    test('handles null dates', () {
      final json = {
        'nomor': 'STR-2024-002',
      };

      final model = StrModel.fromJson(json);

      expect(model.nomor, 'STR-2024-002');
      expect(model.tanggalTerbit, isNull);
      expect(model.berlakuHingga, isNull);
    });

    test('handles missing nomor with empty default', () {
      final json = <String, dynamic>{};
      final model = StrModel.fromJson(json);
      expect(model.nomor, '');
    });

    test('handles null nomor', () {
      final json = {'nomor': null};
      final model = StrModel.fromJson(json);
      expect(model.nomor, '');
    });

    test('parses dates with time component', () {
      final json = {
        'nomor': 'STR-003',
        'tanggal_terbit': '2024-06-15T10:30:00.000',
        'berlaku_hingga': '2027-06-15T23:59:59.000',
      };

      final model = StrModel.fromJson(json);
      expect(model.tanggalTerbit, DateTime(2024, 6, 15, 10, 30));
      expect(model.berlakuHingga, DateTime(2027, 6, 15, 23, 59, 59));
    });

    test('does not crash on malformed dates', () {
      final json = {
        'nomor': 'STR-004',
        'tanggal_terbit': 'not-a-date',
        'berlaku_hingga': '',
      };

      final model = StrModel.fromJson(json);

      expect(model.nomor, 'STR-004');
      expect(model.tanggalTerbit, isNull);
      expect(model.berlakuHingga, isNull);
    });
  });

  group('StrModel.toJson', () {
    test('serializes all fields', () {
      final model = StrModel(
        nomor: 'STR-2024-001',
        tanggalTerbit: DateTime(2024, 1, 15),
        berlakuHingga: DateTime(2027, 1, 15),
      );

      final json = model.toJson();
      expect(json['nomor'], 'STR-2024-001');
      expect(json['tanggal_terbit'], '2024-01-15T00:00:00.000');
      expect(json['berlaku_hingga'], '2027-01-15T00:00:00.000');
    });

    test('serializes null dates', () {
      const model = StrModel(nomor: 'STR-001');
      final json = model.toJson();
      expect(json['tanggal_terbit'], isNull);
      expect(json['berlaku_hingga'], isNull);
    });
  });
}
