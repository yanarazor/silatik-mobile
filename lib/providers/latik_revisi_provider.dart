import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/utils/api_response_utils.dart';
import '../data/models/latik_ext_model.dart';
import '../data/models/registrasi_model.dart';
import '../data/repositories/latik_ext_repository.dart';
import '../data/services/latik_service.dart';
import 'latik_ext_provider.dart' show latikExtRepoProvider;

// ------------------------------------------------------------------- Model

/// Mutable draft overlay on top of an immutable [ExtDokumen] definition.
/// Holds user's chosen file and edited nomor/tanggal for the revisi flow.
class RevisiDokumenDraft {
  final ExtDokumen def;
  final FileItem? file; // null = keep server file unchanged on save
  final String nomor;
  final DateTime? tanggal;

  const RevisiDokumenDraft({
    required this.def,
    this.file,
    this.nomor = '',
    this.tanggal,
  });

  // True when there is a displayable file (new pick or old server URL).
  bool get hasFile => file != null || def.fileUrl.isNotEmpty;

  // File item to show in the card: new pick first, then server URL.
  FileItem? get displayFile {
    if (file != null) return file;
    if (def.fileUrl.isNotEmpty) {
      final name = def.fileUrl.split('/').last.split('?').first;
      return FileItem(
        path: def.fileUrl,
        name: name.isEmpty ? 'dokumen' : name,
        size: 0,
      );
    }
    return null;
  }

  RevisiDokumenDraft copyWith(
      {FileItem? file, String? nomor, DateTime? tanggal}) {
    return RevisiDokumenDraft(
      def: def,
      file: file ?? this.file,
      nomor: nomor ?? this.nomor,
      tanggal: tanggal ?? this.tanggal,
    );
  }
}

// -------------------------------------------------------------------- State

enum LatikRevisiStatus { idle, loading, loaded, saving, submitting, error }

class LatikRevisiState {
  final LatikRevisiStatus status;
  final String refExt;
  final List<RevisiDokumenDraft> dokumen;
  final String? errorMessage;
  final bool hasUnsavedEdits;

  const LatikRevisiState({
    this.status = LatikRevisiStatus.idle,
    this.refExt = '',
    this.dokumen = const [],
    this.errorMessage,
    this.hasUnsavedEdits = false,
  });

  bool get isLoading => status == LatikRevisiStatus.loading;
  bool get isSaving => status == LatikRevisiStatus.saving;
  bool get isSubmitting => status == LatikRevisiStatus.submitting;
  bool get isBusy => isSaving || isSubmitting;

  LatikRevisiState copyWith({
    LatikRevisiStatus? status,
    String? refExt,
    List<RevisiDokumenDraft>? dokumen,
    String? errorMessage,
    bool? hasUnsavedEdits,
  }) {
    return LatikRevisiState(
      status: status ?? this.status,
      refExt: refExt ?? this.refExt,
      dokumen: dokumen ?? this.dokumen,
      errorMessage: errorMessage,
      hasUnsavedEdits: hasUnsavedEdits ?? this.hasUnsavedEdits,
    );
  }
}

// ------------------------------------------------------------------ Notifier

class LatikRevisiNotifier extends StateNotifier<LatikRevisiState> {
  LatikRevisiNotifier(this._repo) : super(const LatikRevisiState());

  final LatikExtRepository _repo;

  // Date format for LATIK revision: DD-MM-YYYY (same as perpanjangan).
  static final DateFormat _uploadDate = DateFormat('dd-MM-yyyy');

  // Fetch returned revisions, select last, load its documents.
  Future<void> load() async {
    state =
        state.copyWith(status: LatikRevisiStatus.loading, errorMessage: null);
    try {
      final rows = await _repo.getRevisi();
      if (rows.isEmpty) {
        state = state.copyWith(status: LatikRevisiStatus.loaded, refExt: '');
        return;
      }

      // The web app uses data[data.length - 1], so last item is authoritative.
      final last = rows.last;
      final refExt = meaningfulString(
        last is Map ? last['ref_ext'] : null,
      );
      if (refExt == null) {
        state = state.copyWith(status: LatikRevisiStatus.loaded, refExt: '');
        return;
      }

      final defs = await _repo.getDokumen(refExt);
      state = state.copyWith(
        status: LatikRevisiStatus.loaded,
        refExt: refExt,
        dokumen: [
          for (final d in defs)
            RevisiDokumenDraft(
              def: d,
              nomor: d.nomor,
              tanggal: parseFlexibleDate(d.tanggal),
            ),
        ],
      );
    } catch (e) {
      state = state.copyWith(
        status: LatikRevisiStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  void setFile(int id, FileItem file) {
    _updateDraft(id, (d) => d.copyWith(file: file));
    state = state.copyWith(hasUnsavedEdits: true);
  }

  void setNomor(int id, String value) {
    _updateDraft(id, (d) => d.copyWith(nomor: value));
    state = state.copyWith(hasUnsavedEdits: true);
  }

  void setTanggal(int id, DateTime value) {
    _updateDraft(id, (d) => d.copyWith(tanggal: value));
    state = state.copyWith(hasUnsavedEdits: true);
  }

  // Validation: names of editable required docs that are still incomplete.
  List<String> get missingRequired => [
        for (final d in state.dokumen)
          if (!d.def.isReadOnly && _incomplete(d)) d.def.namaDokumen,
      ];

  bool _incomplete(RevisiDokumenDraft d) {
    if (d.def.fileRequired && !d.hasFile) return true;
    if (d.def.nomorRequired && d.nomor.trim().isEmpty) return true;
    if (d.def.tanggalRequired && d.tanggal == null) return true;
    return false;
  }

  // Save all documents via POST /latikext/savedokumen (replace-full-state).
  // Unchanged (valid/locked) docs are included with file=null so the service
  // sends "undefined" and the server keeps the existing file.
  Future<void> saveDokumen() async {
    state =
        state.copyWith(status: LatikRevisiStatus.saving, errorMessage: null);
    try {
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
      await _repo.saveDokumen(refExt: state.refExt, uploads: uploads);
      state = state.copyWith(
        status: LatikRevisiStatus.loaded,
        hasUnsavedEdits: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: LatikRevisiStatus.loaded,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Submit revision for re-verification. No invoice step for revisi (web
  // handoff §Flow 1: directly calls requestverifikasi without createinvoice).
  Future<void> submitRevisi() async {
    state = state.copyWith(
        status: LatikRevisiStatus.submitting, errorMessage: null);
    try {
      await _repo.requestVerifikasi(state.refExt);
      state =
          state.copyWith(status: LatikRevisiStatus.loaded, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        status: LatikRevisiStatus.loaded,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  void _updateDraft(
      int id, RevisiDokumenDraft Function(RevisiDokumenDraft) fn) {
    state = state.copyWith(
      dokumen: [
        for (final d in state.dokumen)
          if (d.def.id == id) fn(d) else d,
      ],
    );
  }
}

// ---------------------------------------------------------------- Providers

/// Singleton per-session; autoDispose cleans up when the LATIK revisi flow
/// is fully popped. Key is a unit string constant so there is exactly one
/// instance (unlike perpanjangan which keys by refExt).
final latikRevisiProvider =
    StateNotifierProvider.autoDispose<LatikRevisiNotifier, LatikRevisiState>(
  (ref) => LatikRevisiNotifier(ref.watch(latikExtRepoProvider)),
);
