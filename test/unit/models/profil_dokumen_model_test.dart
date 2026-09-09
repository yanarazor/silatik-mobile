import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/data/models/profil_dokumen.dart';

void main() {
  group('ProfilDokumen.fromJson', () {
    test('memakai jenis_dokumen untuk nama tampil', () {
      final doc = ProfilDokumen.fromJson({
        'nama_dokumen':
            '3d1bf16c_salinan+akta+badan+hukum.pdf', // nama file unggah
        'jenis_dokumen': 'Salinan akta badan hukum',
        'o_dokumen': {'nama_dokumen': 'Salinan akta badan hukum'},
      });
      expect(doc.nama, 'Salinan akta badan hukum');
    });

    test('fallback ke nama o_dokumen saat jenis_dokumen kosong', () {
      final doc = ProfilDokumen.fromJson({
        'nama_dokumen': 'ref_struktur+organisasi.pdf',
        'o_dokumen': {'nama_dokumen': 'Struktur organisasi dan manajemen LATIK'},
      });
      expect(doc.nama, 'Struktur organisasi dan manajemen LATIK');
    });

    test('meratakan \\r\\n di nama tampil', () {
      final doc = ProfilDokumen.fromJson({
        'jenis_dokumen':
            'Tugas pokok dan fungsi LATIK (bagi yang\r\nberstatus bagian dari badan hukum)',
      });
      expect(doc.nama,
          'Tugas pokok dan fungsi LATIK (bagi yang berstatus bagian dari badan hukum)');
    });

    test('bentuk lama tanpa o_dokumen memakai nama_dokumen top-level', () {
      final doc = ProfilDokumen.fromJson({
        'nama_dokumen': '1. Salinan akta badan hukum',
        'isi': {'status_verifikasi': 0},
      });
      expect(doc.nama, '1. Salinan akta badan hukum');
      expect(doc.terverifikasi, isFalse);
    });

    test('membaca nomor, tanggal, url, status, catatan dari item', () {
      final doc = ProfilDokumen.fromJson({
        'id': 440,
        'nomor': 'test',
        'tanggal': '2025-04-15',
        'status_verifikasi': 1,
        'catatan_verifikasi': 'oke',
        'url_dokumen': 'https://minio/pdf/akta.pdf',
        'nama_dokumen': 'akta.pdf',
        'jenis_dokumen': 'Salinan akta badan hukum',
      });
      expect(doc.nomor, 'test');
      expect(doc.tanggal, '2025-04-15');
      expect(doc.url, 'https://minio/pdf/akta.pdf');
      expect(doc.catatan, 'oke');
      expect(doc.terverifikasi, isTrue);
    });

    test('status_verifikasi 0 / null berarti belum terverifikasi', () {
      expect(
        ProfilDokumen.fromJson({'status_verifikasi': 0}).terverifikasi,
        isFalse,
      );
      expect(
        ProfilDokumen.fromJson({'status_verifikasi': null}).terverifikasi,
        isFalse,
      );
    });
  });

  group('ProfilDokumen.listFrom', () {
    test('mengambil array dokumen_kelengkapan di root profil', () {
      final docs = ProfilDokumen.listFrom({
        'dokumen_kelengkapan': [
          {'jenis_dokumen': 'Akta', 'status_verifikasi': 1},
          {'jenis_dokumen': 'NIB', 'status_verifikasi': 0},
        ],
      });
      expect(docs, hasLength(2));
      expect(docs.first.terverifikasi, isTrue);
      expect(docs.last.terverifikasi, isFalse);
    });

    test('membaca array yang tersarang di map o_latik', () {
      final docs = ProfilDokumen.listFrom({
        'o_latik': {
          'dokumen_kelengkapan': [
            {'jenis_dokumen': 'SOP Audit'},
          ],
        },
      });
      expect(docs, hasLength(1));
      expect(docs.first.nama, 'SOP Audit');
    });

    test('record kosong disaring dan list kosong dikembalikan apa adanya', () {
      expect(ProfilDokumen.listFrom({}), isEmpty);
      final docs = ProfilDokumen.listFrom({
        'dokumen_kelengkapan': [
          <String, dynamic>{},
        ],
      });
      expect(docs, isEmpty);
    });
  });
}
