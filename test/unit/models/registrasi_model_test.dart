import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/data/models/registrasi_model.dart';
import 'package:silatik_mobile/data/models/lembaga_model.dart';
import 'package:silatik_mobile/data/models/auditor_model.dart';

void main() {
  group('FileItem', () {
    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'path': '/uploads/doc.pdf',
          'name': 'doc.pdf',
          'size': 2048,
        };
        final item = FileItem.fromJson(json);
        expect(item.path, '/uploads/doc.pdf');
        expect(item.name, 'doc.pdf');
        expect(item.size, 2048);
      });

      test('handles missing fields with defaults', () {
        final json = <String, dynamic>{};
        final item = FileItem.fromJson(json);
        expect(item.path, '');
        expect(item.name, '');
        expect(item.size, 0);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const item = FileItem(path: '/file.pdf', name: 'file.pdf', size: 512);
        final json = item.toJson();
        expect(json['path'], '/file.pdf');
        expect(json['name'], 'file.pdf');
        expect(json['size'], 512);
      });
    });
  });

  group('RegistrasiModel', () {
    test('default constructor has expected defaults', () {
      const model = RegistrasiModel();
      expect(model.lembaga, isNull);
      expect(model.nomorKan, '');
      expect(model.terbitKan, isNull);
      expect(model.berakhirKan, isNull);
      expect(model.ruangLingkup, isEmpty);
      expect(model.sertifikatKan, isNull);
      expect(model.dokumen, isEmpty);
      expect(model.auditors, isEmpty);
      expect(model.pernyataan, isFalse);
    });

    group('copyWith', () {
      test('copies with no changes returns same values', () {
        const lembaga = LembagaModel(
          nama: 'PT Test',
          nib: '123',
          badanHukum: 'PT',
          alamat: 'Jl. Test',
          provinsi: 'Jatim',
          kota: 'Surabaya',
          kodePos: '60112',
          telepon: '031',
          email: 'test@test.com',
        );

        final original = RegistrasiModel(
          lembaga: lembaga,
          nomorKan: 'KAN-001',
          terbitKan: DateTime(2024, 1, 1),
          berakhirKan: DateTime(2027, 1, 1),
          ruangLingkup: ['Audit TI'],
          pernyataan: true,
        );

        final copy = original.copyWith();

        expect(copy.lembaga, same(lembaga));
        expect(copy.nomorKan, 'KAN-001');
        expect(copy.terbitKan, DateTime(2024, 1, 1));
        expect(copy.berakhirKan, DateTime(2027, 1, 1));
        expect(copy.ruangLingkup, ['Audit TI']);
        expect(copy.pernyataan, isTrue);
      });

      test('copies with changes replaces specified fields', () {
        const original = RegistrasiModel(
          nomorKan: 'OLD',
          ruangLingkup: ['Old Scope'],
          pernyataan: false,
        );

        final copy = original.copyWith(
          nomorKan: 'NEW',
          ruangLingkup: ['New Scope'],
          pernyataan: true,
        );

        expect(copy.nomorKan, 'NEW');
        expect(copy.ruangLingkup, ['New Scope']);
        expect(copy.pernyataan, isTrue);
      });

      test('copy preserves lembaga reference', () {
        const lembaga = LembagaModel(
          nama: 'PT Test',
          nib: '123',
          badanHukum: 'PT',
          alamat: '',
          provinsi: '',
          kota: '',
          kodePos: '',
          telepon: '',
          email: '',
        );

        const original = RegistrasiModel(lembaga: lembaga);
        final copy = original.copyWith(nomorKan: 'NEW');

        expect(copy.lembaga, same(lembaga));
      });

      test('copy can replace auditors list', () {
        const original = RegistrasiModel(auditors: []);
        final newAuditors = [
          const AuditorModel(
            id: 'A1',
            nama: 'Auditor 1',
            email: '',
            nik: '',
            tempatLahir: '',
            tanggalLahir: null,
            alamat: '',
            provinsi: '',
            kabupaten: '',
            kodePos: '',
            agama: '',
            phone: '',
            keterangan: '',
            fotoUrl: '',
            nomorSertifikasi: '',
            lembagaPenerbit: '',
            tanggalTerbit: null,
            tanggalBerakhir: null,
            kompetensi: [],
            certificates: [],
            statusLabel: '',
            activeLabel: '',
            verificationLabel: '',
            strTanggalAkhir: null,
            filePath: '',
            fileName: '',
            fileSize: 0,
            ktpFileUrl: '',
            sertifikatKompetensiUrl: '',
            portofolioUrl: '',
            praktikAuditUrl: '',
            asosiasiProfesiUrl: '',
            pernyataanIntegritasUrl: '',
            suratPermohonanUrl: '',
            pengangkatanUrl: '',
          ),
        ];

        final copy = original.copyWith(auditors: newAuditors);
        expect(copy.auditors, hasLength(1));
        expect(copy.auditors.first.nama, 'Auditor 1');
      });
    });
  });
}
