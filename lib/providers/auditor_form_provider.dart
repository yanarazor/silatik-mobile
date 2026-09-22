import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/auditor_model.dart';
import '../data/models/registrasi_model.dart';
import '../data/repositories/auditor_repository.dart';
import '../data/services/auditor_payload.dart';
import 'auditor_provider.dart';
import 'auth_provider.dart';

/// Data Profil Auditor yang dikumpulkan di Step 0. Semua id (provinsi,
/// kabupaten, agama) disimpan sebagai string sesuai kontrak backend.
class AuditorProfilDraft {
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
  final FileItem? foto;

  const AuditorProfilDraft({
    this.nama = '',
    this.nik = '',
    this.email = '',
    this.tempatLahir = '',
    this.tanggalLahir,
    this.phone = '',
    this.provinsi = '',
    this.kabupaten = '',
    this.kodePos = '',
    this.agama = '',
    this.status = '1',
    this.keterangan = '',
    this.foto,
  });

  AuditorProfilDraft copyWith({
    String? nama,
    String? nik,
    String? email,
    String? tempatLahir,
    DateTime? tanggalLahir,
    String? phone,
    String? provinsi,
    String? kabupaten,
    String? kodePos,
    String? agama,
    String? status,
    String? keterangan,
    FileItem? foto,
  }) {
    return AuditorProfilDraft(
      nama: nama ?? this.nama,
      nik: nik ?? this.nik,
      email: email ?? this.email,
      tempatLahir: tempatLahir ?? this.tempatLahir,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      phone: phone ?? this.phone,
      provinsi: provinsi ?? this.provinsi,
      kabupaten: kabupaten ?? this.kabupaten,
      kodePos: kodePos ?? this.kodePos,
      agama: agama ?? this.agama,
      status: status ?? this.status,
      keterangan: keterangan ?? this.keterangan,
      foto: foto ?? this.foto,
    );
  }
}

class AuditorFormState {
  final AuditorProfilDraft profil;

  /// key = `field` Data Dukung dari backend, value = file terpilih/lama.
  final Map<String, FileItem?> dokumen;

  /// null = mode create belum tersimpan; terisi setelah save atau saat edit.
  final String? ref;

  final List<AuditorCertificate> certificates;
  final bool submitting;
  final String? error;

  const AuditorFormState({
    this.profil = const AuditorProfilDraft(),
    this.dokumen = const {},
    this.ref,
    this.certificates = const [],
    this.submitting = false,
    this.error,
  });

  bool get isSaved => ref != null && ref!.isNotEmpty;

  AuditorFormState copyWith({
    AuditorProfilDraft? profil,
    Map<String, FileItem?>? dokumen,
    String? ref,
    List<AuditorCertificate>? certificates,
    bool? submitting,
    String? error,
  }) {
    return AuditorFormState(
      profil: profil ?? this.profil,
      dokumen: dokumen ?? this.dokumen,
      ref: ref ?? this.ref,
      certificates: certificates ?? this.certificates,
      submitting: submitting ?? this.submitting,
      error: error,
    );
  }
}

class AuditorFormNotifier extends StateNotifier<AuditorFormState> {
  AuditorFormNotifier(this._repo) : super(const AuditorFormState());

  final AuditorRepository _repo;

  void setProfil(AuditorProfilDraft profil) =>
      state = state.copyWith(profil: profil);

  void setDoc(String field, FileItem? file) {
    final docs = Map<String, FileItem?>.from(state.dokumen);
    docs[field] = file;
    state = state.copyWith(dokumen: docs);
  }

  /// Prefill untuk mode edit dari auditor + dokumen yang sudah ada di server.
  void initFromAuditor(
    AuditorModel auditor,
    List<AuditorDocument> serverDocs,
  ) {
    final docs = <String, FileItem?>{
      for (final d in serverDocs)
        if (d.field.isNotEmpty)
          d.field: d.url.isEmpty
              ? null
              : FileItem(
                  path: d.url,
                  name: d.url.split('/').last.split('?').first,
                  size: 0,
                ),
    };

    state = AuditorFormState(
      ref: auditor.id,
      profil: AuditorProfilDraft(
        nama: auditor.nama,
        nik: auditor.nik,
        email: auditor.email,
        tempatLahir: auditor.tempatLahir,
        tanggalLahir: auditor.tanggalLahir,
        phone: auditor.phone,
        provinsi: auditor.provinsi,
        kabupaten: auditor.kabupaten,
        kodePos: auditor.kodePos,
        agama: auditor.agama,
        status: (auditor.status ?? 1).toString(),
        keterangan: auditor.keterangan,
        foto: auditor.fotoUrl.isEmpty
            ? null
            : FileItem(
                path: auditor.fotoUrl,
                name: auditor.fotoUrl.split('/').last.split('?').first,
                size: 0,
              ),
      ),
      dokumen: docs,
      certificates: auditor.certificates,
    );
  }

  AuditorProfilPayload _buildPayload() {
    final p = state.profil;
    return AuditorProfilPayload(
      nama: p.nama,
      nik: p.nik,
      email: p.email,
      tempatLahir: p.tempatLahir,
      tanggalLahir: p.tanggalLahir,
      phone: p.phone,
      provinsi: p.provinsi,
      kabupaten: p.kabupaten,
      kodePos: p.kodePos,
      agama: p.agama,
      status: p.status,
      keterangan: p.keterangan,
      foto: p.foto,
      dokumen: state.dokumen,
    );
  }

  /// Kirim Profil + Data Dukung. Create => POST /auditor/save (simpan ref);
  /// edit => POST /auditor/update. Lempar ulang error agar UI bisa menampilkan.
  Future<void> submitProfil() async {
    state = state.copyWith(submitting: true, error: null);
    try {
      final payload = _buildPayload();
      if (state.isSaved) {
        await _repo.update(state.ref!, payload);
      } else {
        final ref = await _repo.save(payload);
        state = state.copyWith(ref: ref);
      }
      state = state.copyWith(submitting: false);
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
      rethrow;
    }
  }

  /// Save one Technical Certification. [auditorRef] must be supplied by the
  /// caller (the standalone screen knows its ref) so it doesn't depend on state
  /// that can be autoDisposed; falls back to state.ref for legacy callers (edit tab).
  Future<void> addSertifikat({
    required String namaPelatihan,
    required String tahun,
    required String lembaga,
    required FileItem sertifikatFile,
    String? auditorRef,
  }) async {
    final ref = (auditorRef != null && auditorRef.isNotEmpty)
        ? auditorRef
        : state.ref;
    if (ref == null || ref.isEmpty) {
      throw StateError('Auditor belum tersimpan');
    }
    state = state.copyWith(submitting: true, error: null);
    try {
      await _repo.saveSertifikasiTeknis(
        refAuditor: ref,
        namaPelatihan: namaPelatihan,
        tahun: tahun,
        lembaga: lembaga,
        sertifikatFile: sertifikatFile,
      );
      state = state.copyWith(submitting: false);
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
      rethrow;
    }
  }
}

/// Family per "sesi form": key opsional = ref auditor yang diedit (null=create).
final auditorFormProvider = StateNotifierProvider.autoDispose
    .family<AuditorFormNotifier, AuditorFormState, String?>((ref, _) {
  return AuditorFormNotifier(ref.watch(auditorRepoProvider));
});

/// Definisi Data Dukung (dengan nama `field` multipart) untuk render dinamis.
final auditorDokumenDefsProvider =
    FutureProvider.autoDispose<List<AuditorDokumenDef>>((ref) {
  return ref.watch(auditorRepoProvider).getDokumenDefs();
});

/// Ukuran berkas dari header `content-length` sebuah URL (HEAD request).
/// Mengembalikan null bila server tak mengirim header atau request gagal —
/// pemanggil cukup tidak menampilkan ukuran.
final fileContentLengthProvider =
    FutureProvider.autoDispose.family<int?, String>((ref, url) async {
  if (url.trim().isEmpty) return null;
  try {
    final dio = ref.watch(dioProvider);
    final res = await dio.head<void>(url);
    final raw = res.headers.value('content-length') ??
        res.headers.value('Content-Length');
    final size = int.tryParse(raw ?? '');
    return (size != null && size > 0) ? size : null;
  } catch (_) {
    return null;
  }
});
