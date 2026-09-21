import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/utils/api_response_utils.dart';
import '../data/models/latik_ext_model.dart';
import '../data/models/registrasi_model.dart';
import '../data/repositories/latik_ext_repository.dart';
import '../data/services/latik_service.dart';
import 'auth_provider.dart';
import 'registrasi_provider.dart' show latikServiceProvider;

final latikExtRepoProvider = Provider(
    (ref) => LatikExtRepository(ref.watch(latikServiceProvider)));

class ExtDokumenDraft {
  final ExtDokumen def;
  final FileItem? file; // berkas baru yang dipilih (lokal)
  final String nomor;
  final DateTime? tanggal;

  const ExtDokumenDraft({
    required this.def,
    this.file,
    this.nomor = '',
    this.tanggal,
  });

  bool get hasFile => file != null || def.fileUrl.isNotEmpty;

  FileItem? get displayFile {
    if (file != null) return file;
    if (def.fileUrl.isNotEmpty) {
      final name = def.fileUrl.split('/').last.split('?').first;
      return FileItem(
          path: def.fileUrl, name: name.isEmpty ? 'dokumen' : name, size: 0);
    }
    return null;
  }

  ExtDokumenDraft copyWith({FileItem? file, String? nomor, DateTime? tanggal}) {
    return ExtDokumenDraft(
      def: def,
      file: file ?? this.file,
      nomor: nomor ?? this.nomor,
      tanggal: tanggal ?? this.tanggal,
    );
  }
}

class LatikExtState {
  final String refExt;
  final List<ExtDokumenDraft> dokumen;
  final bool submitting;
  final String? error;

  final String invoiceRef;

  const LatikExtState({
    this.refExt = '',
    this.dokumen = const [],
    this.submitting = false,
    this.error,
    this.invoiceRef = '',
  });

  LatikExtState copyWith({
    String? refExt,
    List<ExtDokumenDraft>? dokumen,
    bool? submitting,
    String? error,
    String? invoiceRef,
  }) {
    return LatikExtState(
      refExt: refExt ?? this.refExt,
      dokumen: dokumen ?? this.dokumen,
      submitting: submitting ?? this.submitting,
      error: error,
      invoiceRef: invoiceRef ?? this.invoiceRef,
    );
  }
}

class LatikExtNotifier extends StateNotifier<LatikExtState> {
  LatikExtNotifier(this._repo) : super(const LatikExtState());

  final LatikExtRepository _repo;

  static final DateFormat _uploadDate = DateFormat('dd-MM-yyyy');

  Future<void> load(String refExt) async {
    state = state.copyWith(refExt: refExt, submitting: true, error: null);
    try {
      final defs = await _repo.getDokumen(refExt);
      state = state.copyWith(
        submitting: false,
        dokumen: [
          for (final d in defs)
            ExtDokumenDraft(
              def: d,
              nomor: d.nomor,
              tanggal: parseFlexibleDate(d.tanggal),
            ),
        ],
      );
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
      rethrow;
    }
  }

  void setFile(int id, FileItem file) => _update(id, (d) => d.copyWith(file: file));
  void setNomor(int id, String nomor) => _update(id, (d) => d.copyWith(nomor: nomor));
  void setTanggal(int id, DateTime tanggal) =>
      _update(id, (d) => d.copyWith(tanggal: tanggal));

  void _update(int id, ExtDokumenDraft Function(ExtDokumenDraft) fn) {
    state = state.copyWith(
      dokumen: [
        for (final d in state.dokumen) if (d.def.id == id) fn(d) else d,
      ],
    );
  }

  List<String> get missingRequired => [
        for (final d in state.dokumen)
          if (_incomplete(d)) d.def.namaDokumen,
      ];

  bool _incomplete(ExtDokumenDraft d) {
    if (d.def.fileRequired && !d.hasFile) return true;
    if (d.def.nomorRequired && d.nomor.trim().isEmpty) return true;
    if (d.def.tanggalRequired && d.tanggal == null) return true;
    return false;
  }

  Future<String> submit() async {
    state = state.copyWith(submitting: true, error: null);
    try {
      final refExt = state.refExt;

      final uploads = [
        for (final d in state.dokumen)
          DokumenUpload(
            id: d.def.id,
            file: d.file != null ? File(d.file!.path) : null,
            fileName: d.file?.name,
            nomor: d.nomor,
            tanggal: d.tanggal != null ? _uploadDate.format(d.tanggal!) : null,
          ),
      ];
      await _repo.saveDokumen(refExt: refExt, uploads: uploads);

      final invoiceRef = await _repo.createInvoice(refExt);

      await _repo.requestVerifikasi(refExt);

      if (invoiceRef.isNotEmpty) {
        try {
          final kode = await _repo.billing(invoiceRef);
          if (kode.isNotEmpty) {
            await _repo.checkBilling(kode);
          }
        } catch (_) {
        }
      }

      state = state.copyWith(submitting: false, invoiceRef: invoiceRef);
      return invoiceRef;
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
      rethrow;
    }
  }
}

final latikExtProvider = StateNotifierProvider.autoDispose
    .family<LatikExtNotifier, LatikExtState, String>((ref, _) {
  return LatikExtNotifier(ref.watch(latikExtRepoProvider));
});

final latikExtResolveProvider =
    FutureProvider.autoDispose<ExtResolution?>((ref) async {
  final user = ref.watch(authProvider).user;
  final latikRef = user?['latik_ref']?.toString() ?? '';
  if (latikRef.isEmpty) return null;
  return ref.watch(latikExtRepoProvider).resolve(latikRef);
});
