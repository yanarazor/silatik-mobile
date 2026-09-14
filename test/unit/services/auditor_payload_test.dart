import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/data/models/registrasi_model.dart';
import 'package:silatik_mobile/data/services/auditor_payload.dart';

/// Membuat file sementara agar MultipartFile.fromFile punya sumber nyata.
Future<FileItem> _tempFile(String name) async {
  final dir = await Directory.systemTemp.createTemp('auditor_payload_test');
  final file = File('${dir.path}/$name');
  await file.writeAsString('dummy');
  return FileItem(path: file.path, name: name, size: 5);
}

Map<String, String> _fields(FormData fd) => {
      for (final e in fd.fields) e.key: e.value,
    };

Set<String> _fileKeys(FormData fd) => {
      for (final e in fd.files) e.key,
    };

void main() {
  group('AuditorProfilPayload.toFormData (create)', () {
    test('serializes scalars, MM-dd-yyyy date, foto and dynamic doc fields',
        () async {
      final foto = await _tempFile('photo.jpg');
      final ktp = await _tempFile('ktp.pdf');
      final portofolio = await _tempFile('porto.pdf');

      final payload = AuditorProfilPayload(
        nama: 'John Doe',
        nik: '3201010101010001',
        email: 'someone@example.com',
        tempatLahir: 'Jakarta',
        tanggalLahir: DateTime(1990, 5, 21),
        phone: '08123456789',
        provinsi: '11',
        kabupaten: '1101',
        kodePos: '10340',
        agama: '1',
        status: '1',
        keterangan: '',
        foto: foto,
        dokumen: {
          'ktp_file': ktp,
          // `portofolio` sengaja tanpa suffix _file — harus dipakai apa adanya.
          'portofolio': portofolio,
          'praktik_audit_file': null, // belum dipilih → tidak dikirim
        },
      );

      final fd = await payload.toFormData();
      final fields = _fields(fd);

      expect(fields['nama'], 'John Doe');
      expect(fields['nik'], '3201010101010001');
      expect(fields['tanggal_lahir'], '05-21-1990'); // US month-first
      expect(fields['provinsi'], '11');
      expect(fields['kabupaten'], '1101');
      expect(fields['status'], '1');
      expect(fields.containsKey('keterangan'), isTrue); // dikirim walau kosong
      expect(fields.containsKey('ref'), isFalse); // create → tanpa ref

      final files = _fileKeys(fd);
      expect(files, containsAll(<String>['foto', 'ktp_file', 'portofolio']));
      expect(files.contains('praktik_audit_file'), isFalse);
    });
  });

  group('AuditorProfilPayload.toFormData (update)', () {
    test('includes ref and only newly picked (local) doc files', () async {
      final newKtp = await _tempFile('newktp.pdf');

      final payload = AuditorProfilPayload(
        nama: 'John Doe',
        nik: '3201010101010001',
        email: 'someone@example.com',
        tempatLahir: 'Jakarta',
        tanggalLahir: DateTime(1990, 5, 21),
        phone: '08123456789',
        provinsi: '11',
        kabupaten: '1101',
        kodePos: '10340',
        agama: '1',
        status: '1',
        keterangan: 'catatan',
        // foto lama = URL server → tidak dikirim ulang
        foto: const FileItem(
            path: 'https://cdn.example.com/foto.jpg', name: 'foto.jpg', size: 0),
        dokumen: {
          'ktp_file': newKtp, // baru → dikirim
          'portofolio': const FileItem(
              path: 'https://cdn.example.com/porto.pdf',
              name: 'porto.pdf',
              size: 0), // lama → dilewati
        },
      );

      final fd = await payload.toFormData(ref: 'AUDITOR-REF-1');
      final fields = _fields(fd);
      final files = _fileKeys(fd);

      expect(fields['ref'], 'AUDITOR-REF-1');
      expect(files.contains('ktp_file'), isTrue);
      expect(files.contains('portofolio'), isFalse); // tak berubah
      expect(files.contains('foto'), isFalse); // tak berubah
    });
  });

  group('buildSertifikasiTeknisFormData', () {
    test('builds cert multipart with ref_auditor and file', () async {
      final cert = await _tempFile('sertifikat.pdf');
      final fd = await buildSertifikasiTeknisFormData(
        refAuditor: 'AUDITOR-REF-1',
        namaPelatihan: 'Pelatihan SPBE Dasar',
        tahun: '2023',
        lembaga: 'BRIN',
        sertifikatFile: cert,
      );

      final fields = _fields(fd);
      expect(fields['ref_auditor'], 'AUDITOR-REF-1');
      expect(fields['nama_pelatihan'], 'Pelatihan SPBE Dasar');
      expect(fields['tahun'], '2023');
      expect(fields['lembaga'], 'BRIN');
      expect(_fileKeys(fd).contains('sertifikat_file'), isTrue);
    });
  });
}
