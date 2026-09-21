import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/auditor_model.dart';
import '../data/models/latik_ext_model.dart';
import '../data/models/registrasi_model.dart';
import '../data/repositories/auditor_ext_repository.dart';
import '../data/repositories/latik_ext_repository.dart';
import '../data/services/auditor_ext_payload.dart';
import 'auth_provider.dart';
import 'auditor_provider.dart' show auditorServiceProvider;
import 'latik_ext_provider.dart' show ExtDokumenDraft, latikExtRepoProvider;

final auditorExtRepoProvider = Provider(
    (ref) => AuditorExtRepository(ref.watch(auditorServiceProvider)));

List<List<ExtDokumen>>? sliceDokumenPerAuditor(
  List<ExtDokumen> flat,
  int auditorCount,
) {
  if (auditorCount <= 0) return null;
  if (flat.isEmpty) return null;
  if (flat.length % auditorCount != 0) return null;
  final perAuditor = flat.length ~/ auditorCount;
  return [
    for (var i = 0; i < auditorCount; i++)
      flat.sublist(i * perAuditor, (i + 1) * perAuditor),
  ];
}

class AuditorExtState {
  final String refExt;

  final List<AuditorModel> selected;

  final List<ExtDokumen> flatDocs;

  final Map<int, ExtDokumenDraft> drafts;

  final bool submitting;
  final String? error;

  final String? docError;

  final String invoiceRef;

  const AuditorExtState({
    this.refExt = '',
    this.selected = const [],
    this.flatDocs = const [],
    this.drafts = const {},
    this.submitting = false,
    this.error,
    this.docError,
    this.invoiceRef = '',
  });

  AuditorExtState copyWith({
    String? refExt,
    List<AuditorModel>? selected,
    List<ExtDokumen>? flatDocs,
    Map<int, ExtDokumenDraft>? drafts,
    bool? submitting,
    String? error,
    String? docError,
    String? invoiceRef,
  }) {
    return AuditorExtState(
      refExt: refExt ?? this.refExt,
      selected: selected ?? this.selected,
      flatDocs: flatDocs ?? this.flatDocs,
      drafts: drafts ?? this.drafts,
      submitting: submitting ?? this.submitting,
      error: error,
      docError: docError,
      invoiceRef: invoiceRef ?? this.invoiceRef,
    );
  }

  int get perAuditor =>
      selected.isEmpty ? 0 : flatDocs.length ~/ selected.length;
}

class AuditorExtNotifier extends StateNotifier<AuditorExtState> {
  AuditorExtNotifier(this._repo, this._billingRepo, this._latikRef)
      : super(const AuditorExtState());

  final AuditorExtRepository _repo;

  final LatikExtRepository _billingRepo;

  final String _latikRef;

  Future<void> selectAndLoad(String refExt, List<AuditorModel> selected) async {
    state = state.copyWith(
      refExt: refExt,
      selected: selected,
      submitting: true,
      error: null,
      docError: null,
    );
    try {
      final refs = selected.map((a) => a.id).toList();
      await _repo.saveSelection(
        latikRef: _latikRef,
        latikExt: refExt,
        auditorRefs: refs,
      );
      final flat = await _repo.getDokumen(refExt, refs);

      if (selected.isEmpty || flat.length % selected.length != 0) {
        state = state.copyWith(
          submitting: false,
          flatDocs: flat,
          docError:
              'Data dokumen tidak sesuai dengan jumlah auditor terpilih. '
              'Silakan coba lagi.',
        );
        return;
      }

      state = state.copyWith(
        submitting: false,
        flatDocs: flat,
        drafts: {
          for (final d in flat)
            d.id: ExtDokumenDraft(def: d, nomor: d.nomor),
        },
      );
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
      rethrow;
    }
  }

  List<ExtDokumen> docsForAuditor(int index) {
    final blocks = sliceDokumenPerAuditor(state.flatDocs, state.selected.length);
    if (blocks == null || index < 0 || index >= blocks.length) return const [];
    return blocks[index];
  }

  void setFile(int docId, FileItem file) =>
      _update(docId, (d) => d.copyWith(file: file));
  void setNomor(int docId, String nomor) =>
      _update(docId, (d) => d.copyWith(nomor: nomor));
  void setTanggal(int docId, DateTime tanggal) =>
      _update(docId, (d) => d.copyWith(tanggal: tanggal));

  void _update(int docId, ExtDokumenDraft Function(ExtDokumenDraft) fn) {
    final draft = state.drafts[docId];
    if (draft == null) return;
    state = state.copyWith(drafts: {...state.drafts, docId: fn(draft)});
  }

  bool isAuditorComplete(int index) {
    final docs = docsForAuditor(index);
    if (docs.isEmpty) return false;
    for (final d in docs) {
      final draft = state.drafts[d.id];
      if (draft == null) return false;
      if (d.fileRequired && !draft.hasFile) return false;
      if (d.nomorRequired && draft.nomor.trim().isEmpty) return false;
      if (d.tanggalRequired && draft.tanggal == null) return false;
    }
    return true;
  }

  bool get allComplete {
    if (state.selected.isEmpty || state.docError != null) return false;
    for (var i = 0; i < state.selected.length; i++) {
      if (!isAuditorComplete(i)) return false;
    }
    return true;
  }

  Future<String> submit() async {
    state = state.copyWith(submitting: true, error: null);
    try {
      final refExt = state.refExt;

      final batches = <AuditorExtBatch>[];
      for (var i = 0; i < state.selected.length; i++) {
        final docs = docsForAuditor(i);
        batches.add(AuditorExtBatch(
          auditorRef: state.selected[i].id,
          dokumens: [
            for (final d in docs)
              () {
                final draft = state.drafts[d.id];
                return AuditorExtDokumenUpload(
                  id: d.id,
                  file: draft?.file != null ? File(draft!.file!.path) : null,
                  fileName: draft?.file?.name,
                  nomor: draft?.nomor ?? '',
                  tanggal: draft?.tanggal,
                );
              }(),
          ],
        ));
      }

      await _repo.saveDokumen(
        latikRef: _latikRef,
        latikExt: refExt,
        batches: batches,
      );

      final invoiceRef = await _repo.createInvoice(
        latikRef: _latikRef,
        latikExt: refExt,
        auditors: [
          for (final a in state.selected)
            AuditorExtInvoiceItem(nama: a.nama, ref: a.id),
        ],
      );

      await _repo.requestVerifikasi(refExt);

      if (invoiceRef.isNotEmpty) {
        try {
          final kode = await _billingRepo.billing(invoiceRef);
          if (kode.isNotEmpty) {
            await _billingRepo.checkBilling(kode);
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

final auditorExtProvider = StateNotifierProvider.autoDispose
    .family<AuditorExtNotifier, AuditorExtState, String>((ref, _) {
  final user = ref.watch(authProvider).user;
  final latikRef = user?['latik_ref']?.toString() ?? '';
  return AuditorExtNotifier(
    ref.watch(auditorExtRepoProvider),
    ref.watch(latikExtRepoProvider),
    latikRef,
  );
});

final auditorExtResolveProvider =
    FutureProvider.autoDispose<ExtResolution?>((ref) async {
  final user = ref.watch(authProvider).user;
  final latikRef = user?['latik_ref']?.toString() ?? '';
  if (latikRef.isEmpty) return null;
  return ref.watch(auditorExtRepoProvider).resolve(latikRef);
});
