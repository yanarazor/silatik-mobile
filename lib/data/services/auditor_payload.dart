import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../models/registrasi_model.dart';

class AuditorProfilPayload {
  final String nama;
  final String nik;
  final String email;
  final String tempatLahir;
  final DateTime? tanggalLahir;
  final String phone;
  final String provinsi; // id
  final String kabupaten; // id
  final String kodePos;
  final String agama; // id
  final String status; // '1' | '0'
  final String keterangan;

  /// Foto auditor (wajib saat create). Path bisa lokal (baru) atau URL (lama).
  final FileItem? foto;

  /// Peta Data Dukung: key = `field` dari backend, value = file terpilih.
  final Map<String, FileItem?> dokumen;

  const AuditorProfilPayload({
    required this.nama,
    required this.nik,
    required this.email,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.phone,
    required this.provinsi,
    required this.kabupaten,
    required this.kodePos,
    required this.agama,
    required this.status,
    required this.keterangan,
    required this.foto,
    required this.dokumen,
  });

  static final DateFormat _dob = DateFormat('MM-dd-yyyy');

  static bool _isLocalFile(FileItem? f) {
    if (f == null) return false;
    final p = f.path.trim().toLowerCase();
    if (p.isEmpty) return false;
    return !p.startsWith('http://') && !p.startsWith('https://');
  }

  /// [ref] null = create; non-null = update (hanya file baru yang dikirim).
  Future<FormData> toFormData({String? ref}) async {
    final map = <String, dynamic>{};

    void putText(String key, String value) {
      if (value.trim().isNotEmpty) map[key] = value;
    }

    if (ref != null && ref.isNotEmpty) map['ref'] = ref;

    putText('nama', nama);
    putText('nik', nik);
    putText('email', email);
    putText('tempat_lahir', tempatLahir);
    if (tanggalLahir != null) map['tanggal_lahir'] = _dob.format(tanggalLahir!);
    putText('phone', phone);
    putText('provinsi', provinsi);
    putText('kabupaten', kabupaten);
    putText('kode_post', kodePos);
    putText('agama', agama);
    putText('status', status);
    // keterangan boleh string kosong (dokumen mengirim `keterangan=`).
    map['keterangan'] = keterangan;

    // foto: hanya kirim kalau file lokal baru.
    if (_isLocalFile(foto)) {
      map['foto'] =
          await MultipartFile.fromFile(foto!.path, filename: foto!.name);
    }

    // Data Dukung dinamis: hanya file lokal baru yang dikirim.
    for (final entry in dokumen.entries) {
      final field = entry.key;
      final file = entry.value;
      if (field.isEmpty) continue;
      if (_isLocalFile(file)) {
        map[field] =
            await MultipartFile.fromFile(file!.path, filename: file.name);
      }
    }

    return FormData.fromMap(map);
  }
}

/// Body multipart untuk POST /auditor/simpansertifikasiteknis (satu sertifikat).
Future<FormData> buildSertifikasiTeknisFormData({
  required String refAuditor,
  required String namaPelatihan,
  required String tahun,
  required String lembaga,
  required FileItem sertifikatFile,
}) async {
  return FormData.fromMap({
    'ref_auditor': refAuditor,
    'nama_pelatihan': namaPelatihan,
    'tahun': tahun,
    'lembaga': lembaga,
    'sertifikat_file': await MultipartFile.fromFile(
      sertifikatFile.path,
      filename: sertifikatFile.name,
    ),
  });
}
