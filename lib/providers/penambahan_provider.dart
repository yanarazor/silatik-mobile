import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/auditor_model.dart';
import '../data/repositories/auditor_ext_repository.dart';
import '../data/repositories/latik_ext_repository.dart';
import '../data/services/auditor_ext_payload.dart';
import 'auth_provider.dart';
import 'auditor_ext_provider.dart' show auditorExtRepoProvider;
import 'latik_ext_provider.dart' show latikExtRepoProvider;

/// State submit pengajuan Penambahan Auditor (satu auditor per pengajuan).
class PenambahanState {
  final bool submitting;
  final String? error;
  final String invoiceRef;

  const PenambahanState({
    this.submitting = false,
    this.error,
    this.invoiceRef = '',
  });

  PenambahanState copyWith({
    bool? submitting,
    String? error,
    String? invoiceRef,
  }) {
    return PenambahanState(
      submitting: submitting ?? this.submitting,
      error: error,
      invoiceRef: invoiceRef ?? this.invoiceRef,
    );
  }
}

/// Orkestrasi submit penambahan (spec §4, disederhanakan untuk satu auditor):
/// createinvoice(is_new=3) -> requestverifikasi(per auditor) -> billing tail
/// (best-effort). Kembalikan ref invoice.
class PenambahanNotifier extends StateNotifier<PenambahanState> {
  PenambahanNotifier(this._repo, this._billingRepo, this._latikRef)
      : super(const PenambahanState());

  final AuditorExtRepository _repo;
  final LatikExtRepository _billingRepo;
  final String _latikRef;

  Future<String> submit(AuditorModel auditor) async {
    state = state.copyWith(submitting: true, error: null);
    try {
      // 1. Buat invoice penambahan. Harus sukses sebelum requestverifikasi.
      final invoiceRef = await _repo.createAddInvoice([
        AuditorAddInvoiceItem(
          ref: auditor.id,
          nama: auditor.nama,
          status: auditor.status,
        ),
      ]);

      // 2. Ajukan verifikasi untuk auditor ini.
      await _repo.requestVerifikasiPenambahan(auditor.id);

      // 3. Billing tail (best-effort): kode tagihan boleh menyusul di layar
      // transaksi bila gagal — pengajuan yang sudah sukses jangan digagalkan.
      if (invoiceRef.isNotEmpty) {
        try {
          final kode = await _billingRepo.billing(
            invoiceRef,
            refLatik: _latikRef,
          );
          if (kode.isNotEmpty) {
            await _billingRepo.checkBilling(kode);
          }
        } catch (_) {
          // ponytail: billing best-effort; abaikan kegagalan di tahap ini.
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

final penambahanProvider =
    StateNotifierProvider.autoDispose<PenambahanNotifier, PenambahanState>(
        (ref) {
  final user = ref.watch(authProvider).user;
  final latikRef = user?['latik_ref']?.toString() ?? '';
  return PenambahanNotifier(
    ref.watch(auditorExtRepoProvider),
    ref.watch(latikExtRepoProvider),
    latikRef,
  );
});
