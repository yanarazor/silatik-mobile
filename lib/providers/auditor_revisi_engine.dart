import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/api_response_utils.dart';
import '../data/models/auditor_model.dart';
import '../data/models/latik_ext_model.dart';
import '../data/models/registrasi_model.dart';
import '../data/services/auditor_ext_payload.dart';
import 'auditor_ext_provider.dart' show sliceDokumenPerAuditor;
import 'latik_ext_provider.dart' show ExtDokumenDraft;

enum AuditorRevisiStatus { idle, loading, loaded, saving, submitting, error }

class AuditorRevisiState {
  final AuditorRevisiStatus status;
  final List<AuditorModel> allAuditors;
  final Set<String> selectedIds;
  final List<ExtDokumen> flatDocs;
  final Map<int, ExtDokumenDraft> drafts;
  final bool hasUnsavedEdits;
  final String? errorMessage;
  final String? docError;

  const AuditorRevisiState({
    this.status = AuditorRevisiStatus.idle,
    this.allAuditors = const [],
    this.selectedIds = const {},
    this.flatDocs = const [],
    this.drafts = const {},
    this.hasUnsavedEdits = false,
    this.errorMessage,
    this.docError,
  });

  bool get isLoading => status == AuditorRevisiStatus.loading;
  bool get isSaving => status == AuditorRevisiStatus.saving;
  bool get isSubmitting => status == AuditorRevisiStatus.submitting;
  bool get isBusy => isSaving || isSubmitting;

  List<AuditorModel> get selectedAuditors =>
      allAuditors.where((a) => selectedIds.contains(a.id)).toList();

  AuditorRevisiState copyWith({
    AuditorRevisiStatus? status,
    List<AuditorModel>? allAuditors,
    Set<String>? selectedIds,
    List<ExtDokumen>? flatDocs,
    Map<int, ExtDokumenDraft>? drafts,
    bool? hasUnsavedEdits,
    String? errorMessage,
    String? docError,
  }) {
    return AuditorRevisiState(
      status: status ?? this.status,
      allAuditors: allAuditors ?? this.allAuditors,
      selectedIds: selectedIds ?? this.selectedIds,
      flatDocs: flatDocs ?? this.flatDocs,
      drafts: drafts ?? this.drafts,
      hasUnsavedEdits: hasUnsavedEdits ?? this.hasUnsavedEdits,
      errorMessage: errorMessage,
      docError: docError,
    );
  }
}

abstract class AuditorRevisiStrategy {
  bool get includeExtensionRefOnSave;
  Future<List<AuditorModel>> loadRevisiAuditors();
  Future<List<ExtDokumen>> loadRevisionDocuments(List<AuditorModel> selected);
  Future<void> saveDocuments({
    required String latikRef,
    required List<AuditorRevisiBatch> batches,
  });
  Future<void> requestVerification(List<AuditorModel> selected);
}

class AuditorRevisiNotifier extends StateNotifier<AuditorRevisiState> {
  AuditorRevisiNotifier({
    required this.strategy,
    required this.latikRef,
  }) : super(const AuditorRevisiState());

  final AuditorRevisiStrategy strategy;
  final String latikRef;

  Future<void> load() async {
    state = state.copyWith(
      status: AuditorRevisiStatus.loading,
      errorMessage: null,
      docError: null,
    );
    try {
      final auditors = await strategy.loadRevisiAuditors();
      if (auditors.isEmpty) {
        state = state.copyWith(
          status: AuditorRevisiStatus.loaded,
          allAuditors: const [],
          selectedIds: const {},
          flatDocs: const [],
          drafts: const {},
        );
        return;
      }

      final selectedIds = auditors.map((a) => a.id).toSet();
      state = state.copyWith(
        allAuditors: auditors,
        selectedIds: selectedIds,
      );
      await loadDocumentsForSelected();
    } catch (e) {
      state = state.copyWith(
        status: AuditorRevisiStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  void toggleAuditor(String id, bool selected) {
    final updated = Set<String>.from(state.selectedIds);
    selected ? updated.add(id) : updated.remove(id);
    state = state.copyWith(selectedIds: updated, hasUnsavedEdits: true);
  }

  Future<void> loadDocumentsForSelected() async {
    final selected = state.selectedAuditors;
    if (selected.isEmpty) {
      state = state.copyWith(
        status: AuditorRevisiStatus.loaded,
        flatDocs: const [],
        drafts: const {},
        docError: null,
      );
      return;
    }

    state = state.copyWith(status: AuditorRevisiStatus.loading, docError: null);
    try {
      final flat = await strategy.loadRevisionDocuments(selected);
      if (flat.length % selected.length != 0) {
        state = state.copyWith(
          status: AuditorRevisiStatus.loaded,
          flatDocs: flat,
          docError: 'Data dokumen tidak sesuai dengan jumlah auditor terpilih. '
              'Silakan coba lagi.',
        );
        return;
      }

      final drafts = <int, ExtDokumenDraft>{};
      for (final doc in flat) {
        drafts[doc.id] = ExtDokumenDraft(
          def: doc,
          nomor: doc.nomor,
          tanggal: parseFlexibleDate(doc.tanggal),
        );
      }
      state = state.copyWith(
        status: AuditorRevisiStatus.loaded,
        flatDocs: flat,
        drafts: drafts,
        hasUnsavedEdits: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuditorRevisiStatus.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  List<ExtDokumen> docsForAuditor(int index) {
    final selected = state.selectedAuditors;
    final blocks = sliceDokumenPerAuditor(state.flatDocs, selected.length);
    if (blocks == null || index < 0 || index >= blocks.length) return const [];
    return blocks[index];
  }

  void setFile(int docId, FileItem file) {
    _updateDraft(docId, (d) => d.copyWith(file: file));
    state = state.copyWith(hasUnsavedEdits: true);
  }

  void setNomor(int docId, String value) {
    _updateDraft(docId, (d) => d.copyWith(nomor: value));
    state = state.copyWith(hasUnsavedEdits: true);
  }

  void setTanggal(int docId, DateTime value) {
    _updateDraft(docId, (d) => d.copyWith(tanggal: value));
    state = state.copyWith(hasUnsavedEdits: true);
  }

  List<String> get missingRequired {
    final result = <String>[];
    final selected = state.selectedAuditors;
    for (var i = 0; i < selected.length; i++) {
      for (final doc in docsForAuditor(i)) {
        final draft = state.drafts[doc.id];
        if (draft == null || doc.isReadOnly) continue;
        if (doc.fileRequired && !draft.hasFile) {
          result.add('${doc.namaDokumen} (${selected[i].nama})');
        } else if (doc.nomorRequired && draft.nomor.trim().isEmpty) {
          result.add('${doc.namaDokumen} (${selected[i].nama})');
        } else if (doc.tanggalRequired && draft.tanggal == null) {
          result.add('${doc.namaDokumen} (${selected[i].nama})');
        }
      }
    }
    return result;
  }

  Future<void> saveDokumen() async {
    state = state.copyWith(
      status: AuditorRevisiStatus.saving,
      errorMessage: null,
    );
    try {
      final selected = state.selectedAuditors;
      final batches = <AuditorRevisiBatch>[];
      for (var i = 0; i < selected.length; i++) {
        final auditor = selected[i];
        final docs = docsForAuditor(i);
        final uploads = <AuditorRevisiDokumenUpload>[];
        for (final doc in docs) {
          final draft = state.drafts[doc.id];
          if (draft?.file != null) {
            uploads.add(AuditorRevisiDokumenUpload(
              file: File(draft!.file!.path),
              fileName: draft.file!.name,
              nomor: draft.nomor,
              tanggal: draft.tanggal,
            ));
          }
        }
        final refExt = strategy.includeExtensionRefOnSave
            ? (auditor.auditorExt.isNotEmpty
                ? auditor.auditorExt.first.latikExt
                : '')
            : null;
        batches.add(AuditorRevisiBatch(
          auditorRef: auditor.id,
          refExt: refExt,
          dokumens: uploads,
        ));
      }
      await strategy.saveDocuments(latikRef: latikRef, batches: batches);
      state = state.copyWith(
        status: AuditorRevisiStatus.loaded,
        hasUnsavedEdits: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuditorRevisiStatus.loaded,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> submit() async {
    state = state.copyWith(
      status: AuditorRevisiStatus.submitting,
      errorMessage: null,
    );
    try {
      await strategy.requestVerification(state.selectedAuditors);
      state = state.copyWith(status: AuditorRevisiStatus.loaded);
    } catch (e) {
      state = state.copyWith(
        status: AuditorRevisiStatus.loaded,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  void _updateDraft(int id, ExtDokumenDraft Function(ExtDokumenDraft) update) {
    final current = state.drafts[id];
    if (current == null) return;
    state = state.copyWith(
      drafts: {...state.drafts, id: update(current)},
    );
  }
}
