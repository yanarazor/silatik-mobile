import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/data/models/auditor_model.dart';

void main() {
  group('AuditorModel.fromJson', () {
    test('parses complete JSON with primary keys', () {
      final json = {
        'ref': 'AUD-001',
        'nama': 'Budi Santoso',
        'email': 'budi@test.com',
        'nik': '3201234567890001',
        'tempat_lahir': 'Jakarta',
        'tanggal_lahir': '1990-05-15',
        'alamat': 'Jl. Sudirman No. 1',
        'provinsi': 'DKI Jakarta',
        'kabupaten': 'Jakarta Selatan',
        'kode_pos': '12190',
        'agama': 'Islam',
        'phone': '08123456789',
        'keterangan': 'Aktif',
        'foto_url': 'https://example.com/foto.jpg',
        'nomor_sertifikasi': 'SERT-001',
        'lembaga_penerbit': 'BRIN',
        'tanggal_terbit': '2023-01-01',
        'tanggal_berakhir': '2026-01-01',
        'kompetensi': ['Keamanan Jaringan', 'Audit TI'],
        'certificates': [
          {
            'nama_pelatihan': 'Cert A',
            'lembaga': 'Lembaga A',
            'tahun': '2023',
            'sertifikat_file_url': 'https://example.com/cert.pdf',
          },
        ],
        'status': 1,
        'status_aktif': 1,
        'status_verifikasi': 1,
        'str_tanggal_akhir': '2025-12-31',
        'file_path': '/files/doc.pdf',
        'file_name': 'doc.pdf',
        'file_size': 1024,
        'ktp_file': 'https://example.com/ktp.pdf',
        'sertifikat_kompetensi_file': 'https://example.com/sertif.pdf',
        'portofolio': 'https://example.com/porto.pdf',
        'praktik_audit_file': 'https://example.com/audit.pdf',
        'asosiasi_profesi_file': 'https://example.com/asosiasi.pdf',
        'pernyataan_integritas_file': 'https://example.com/integritas.pdf',
        'surat_permohonan_file': 'https://example.com/permohonan.pdf',
        'pengangkatan_file': 'https://example.com/pengangkatan.pdf',
      };

      final model = AuditorModel.fromJson(json);

      expect(model.id, 'AUD-001');
      expect(model.nama, 'Budi Santoso');
      expect(model.email, 'budi@test.com');
      expect(model.nik, '3201234567890001');
      expect(model.tempatLahir, 'Jakarta');
      expect(model.tanggalLahir, DateTime(1990, 5, 15));
      expect(model.alamat, 'Jl. Sudirman No. 1');
      expect(model.provinsi, 'DKI Jakarta');
      expect(model.kabupaten, 'Jakarta Selatan');
      expect(model.kodePos, '12190');
      expect(model.agama, 'Islam');
      expect(model.phone, '08123456789');
      expect(model.keterangan, 'Aktif');
      expect(model.fotoUrl, 'https://example.com/foto.jpg');
      expect(model.nomorSertifikasi, 'SERT-001');
      expect(model.lembagaPenerbit, 'BRIN');
      expect(model.tanggalTerbit, DateTime(2023, 1, 1));
      expect(model.tanggalBerakhir, DateTime(2026, 1, 1));
      expect(model.kompetensi, ['Keamanan Jaringan', 'Audit TI']);
      expect(model.certificates, hasLength(1));
      expect(model.certificates.first.nama, 'Cert A');
      expect(model.statusLabel, 'Auditor TIK Tetap');
      expect(model.activeLabel, 'Aktif');
      expect(model.verificationLabel, 'Sudah Verifikasi');
      expect(model.strTanggalAkhir, DateTime(2025, 12, 31));
      expect(model.fileSize, 1024);
      expect(model.ktpFileUrl, 'https://example.com/ktp.pdf');
    });

    test('falls back to alternative JSON keys', () {
      final json = {
        'id': 'ALT-001',
        'name': 'Siti Aminah',
        'identity_number': '3301234567890002',
        'birth_place': 'Bandung',
        'birth_date': '1985-03-20',
        'address': 'Jl. Asia Afrika',
        'province': 'Jawa Barat',
        'city': 'Bandung',
        'postal_code': '40112',
        'telepon': '0876543210',
        'photo_url': 'https://example.com/photo.jpg',
        'no_sertifikat': 'SERT-002',
        'issuer': 'KAN',
        'terbit': '2022-06-15',
        'berakhir': '2025-06-15',
        'kompetensis': ['Forensik Digital'],
        'sertifikat': [
          {
            'nama': 'Cert B',
            'issuer': 'Issuer B',
            'tahun': '2022',
            'file_url': 'https://example.com/certb.pdf',
          },
        ],
        'status': 0,
        'active': 0,
        'status_verifikasi': 0,
      };

      final model = AuditorModel.fromJson(json);

      expect(model.id, 'ALT-001');
      expect(model.nama, 'Siti Aminah');
      expect(model.nik, '3301234567890002');
      expect(model.tempatLahir, 'Bandung');
      expect(model.tanggalLahir, DateTime(1985, 3, 20));
      expect(model.provinsi, 'Jawa Barat');
      expect(model.kabupaten, 'Bandung');
      expect(model.kodePos, '40112');
      expect(model.phone, '0876543210');
      expect(model.fotoUrl, 'https://example.com/photo.jpg');
      expect(model.nomorSertifikasi, 'SERT-002');
      expect(model.lembagaPenerbit, 'KAN');
      expect(model.kompetensi, ['Forensik Digital']);
      expect(model.statusLabel, 'Auditor TIK Tidak Tetap');
      expect(model.activeLabel, 'Tidak Aktif');
      expect(model.verificationLabel, 'Belum Verifikasi');
    });

    test('handles null/missing fields with defaults', () {
      final json = <String, dynamic>{};
      final model = AuditorModel.fromJson(json);

      expect(model.id, '');
      expect(model.nama, '');
      expect(model.email, '');
      expect(model.nik, '');
      expect(model.tempatLahir, '');
      expect(model.tanggalLahir, isNull);
      expect(model.alamat, '');
      expect(model.kompetensi, isEmpty);
      expect(model.certificates, isEmpty);
      expect(model.statusLabel, 'Auditor TIK Tidak Tetap');
      expect(model.activeLabel, 'Tidak Aktif');
      expect(model.verificationLabel, 'Belum Verifikasi');
      expect(model.fileSize, 0);
    });

    test('parses kompetensi from comma-separated string', () {
      final json = {
        'kompetensi': 'Keamanan Jaringan, Audit TI, Forensik',
      };
      final model = AuditorModel.fromJson(json);
      expect(model.kompetensi, ['Keamanan Jaringan', 'Audit TI', 'Forensik']);
    });

    test('derives kompetensi from certificates when empty', () {
      final json = {
        'kompetensi': [],
        'certificates': [
          {'nama_pelatihan': 'Cert X', 'lembaga': 'Lembaga X', 'tahun': '2024'},
          {'nama_pelatihan': 'Cert Y', 'lembaga': 'Lembaga Y', 'tahun': '2023'},
        ],
      };
      final model = AuditorModel.fromJson(json);
      expect(model.kompetensi, ['Cert X', 'Cert Y']);
    });

    test('filters out certificates with empty nama and fileUrl', () {
      final json = {
        'certificates': [
          {'nama_pelatihan': 'Valid Cert'},
          {'nama_pelatihan': ''},
          {'sertifikat_file_url': 'https://example.com/file.pdf'},
        ],
      };
      final model = AuditorModel.fromJson(json);
      expect(model.certificates, hasLength(2));
    });

    test('parses file_size as string to int', () {
      final json = {'file_size': '2048'};
      final model = AuditorModel.fromJson(json);
      expect(model.fileSize, 2048);
    });
  });

  group('AuditorModel.toJson', () {
    test('serializes all fields correctly', () {
      const model = AuditorModel(
        id: 'AUD-001',
        nama: 'Budi',
        email: 'budi@test.com',
        nik: '3201234567890001',
        tempatLahir: 'Jakarta',
        tanggalLahir: null,
        alamat: 'Jl. Sudirman',
        provinsi: 'DKI Jakarta',
        kabupaten: 'Jakarta Selatan',
        kodePos: '12190',
        agama: 'Islam',
        phone: '08123456789',
        keterangan: '',
        fotoUrl: '',
        nomorSertifikasi: 'SERT-001',
        lembagaPenerbit: 'BRIN',
        tanggalTerbit: null,
        tanggalBerakhir: null,
        kompetensi: ['Audit TI'],
        certificates: [],
        statusLabel: 'Auditor TIK Tetap',
        activeLabel: 'Aktif',
        verificationLabel: 'Sudah Verifikasi',
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
      );

      final json = model.toJson();
      expect(json['id'], 'AUD-001');
      expect(json['nama'], 'Budi');
      expect(json['email'], 'budi@test.com');
      expect(json['nik'], '3201234567890001');
      expect(json['kompetensi'], ['Audit TI']);
      expect(json['certificates'], isEmpty);
      expect(json['tanggal_lahir'], isNull);
    });
  });

  group('AuditorCertificate', () {
    test('toJson serializes correctly', () {
      const cert = AuditorCertificate(
        nama: 'Cert A',
        lembaga: 'Lembaga A',
        tahun: '2023',
        fileUrl: 'https://example.com/cert.pdf',
      );
      final json = cert.toJson();
      expect(json['nama'], 'Cert A');
      expect(json['lembaga'], 'Lembaga A');
      expect(json['tahun'], '2023');
      expect(json['file_url'], 'https://example.com/cert.pdf');
    });
  });
}
