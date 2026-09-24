import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/auditor_model.dart';
import '../data/repositories/latik_verifikasi_repository.dart';
import '../data/services/auditor_ext_payload.dart';
import '../data/services/latik_service.dart';
import 'latik_service_provider.dart';

final latikVerifikasiRepoProvider = Provider(
    (ref) => LatikVerifikasiRepository(ref.watch(latikServiceProvider)));

const String kStatusRejected = '2';

enum VerifikasiAction {
  wizard,
  transaksi,
  detail,
}

VerifikasiAction verifikasiActionFor(String status) {
  switch (status.trim()) {
    case '0': // Not Verified / Registration (draft)
    case '2': // Returned (resubmit)
      return VerifikasiAction.wizard;
    case '8': // Awaiting Payment
      return VerifikasiAction.transaksi;
    default:
      return VerifikasiAction.detail;
  }
}

class LatikVerifikasiState {
  final List<AuditorModel> selected;
  final bool submitting;
  final String? error;

  final String invoiceRef;

  const LatikVerifikasiState({
    this.selected = const [],
    this.submitting = false,
    this.error,
    this.invoiceRef = '',
  });

  LatikVerifikasiState copyWith({
    List<AuditorModel>? selected,
    bool? submitting,
    String? error,
    String? invoiceRef,
  }) {
    return LatikVerifikasiState(
      selected: selected ?? this.selected,
      submitting: submitting ?? this.submitting,
      error: error,
      invoiceRef: invoiceRef ?? this.invoiceRef,
    );
  }

  bool get hasSelection => selected.isNotEmpty;
  bool get hasTetap => selected.any((a) => a.status == 1);
  bool get gatePassed => hasSelection && hasTetap;
}

class LatikVerifikasiNotifier extends StateNotifier<LatikVerifikasiState> {
  LatikVerifikasiNotifier(this._repo, this._latikRef)
      : super(const LatikVerifikasiState());

  final LatikVerifikasiRepository _repo;

  final String _latikRef;

  void toggle(AuditorModel auditor, bool on) {
    final next = List<AuditorModel>.from(state.selected);
    if (on) {
      if (!next.any((a) => a.id == auditor.id)) next.add(auditor);
    } else {
      next.removeWhere((a) => a.id == auditor.id);
    }
    state = state.copyWith(selected: next);
  }

  bool isSelected(AuditorModel auditor) =>
      state.selected.any((a) => a.id == auditor.id);

  Future<String> submit({
    required String status,
    required List<DokumenUpload> uploads,
  }) async {
    state = state.copyWith(submitting: true, error: null);
    try {
      // Branch A — resubmit for returned application: no new invoice.
      if (status == kStatusRejected) {
        await _repo.requestVerifikasi(_latikRef);
        state = state.copyWith(submitting: false, invoiceRef: '');
        return '';
      }

      // Branch B — initial registration.
      // 1. Save ALL documents (replace full state).
      await _repo.saveDokumen(uploads);

      // 2. Create invoice (is_new=1) from selected auditors → invoice ref.
      final invoiceRef = await _repo.createInvoice([
        for (final a in state.selected)
          LatikRegAuditorItem(ref: a.id, nama: a.nama, status: a.status),
      ]);

      // 3. Mark data as confirmed.
      await _repo.konfirmasiData();

      // 4. Billing tail: generate billing code then poll once (best-effort).
      // Billing failure must not cancel an already successful submission;
      // user is still redirected to the transaction screen where the code may appear later.
      if (invoiceRef.isNotEmpty) {
        try {
          final kode = await _repo.billing(invoiceRef, refLatik: _latikRef);
          if (kode.isNotEmpty) {
            await _repo.checkBilling(kode);
          }
        } catch (_) {
          // ponytail: billing best-effort; billing code may appear later on the
          // transaction screen. Do not fail submission because of it.
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

final latikVerifikasiProvider = StateNotifierProvider.autoDispose
    .family<LatikVerifikasiNotifier, LatikVerifikasiState, String>(
        (ref, latikRef) {
  return LatikVerifikasiNotifier(
    ref.watch(latikVerifikasiRepoProvider),
    latikRef,
  );
});
