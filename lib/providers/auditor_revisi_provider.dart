import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/auditor_model.dart';
import '../data/models/latik_ext_model.dart';
import '../data/repositories/auditor_ext_repository.dart';
import '../data/services/auditor_ext_payload.dart';
import 'auditor_ext_provider.dart' show auditorExtRepoProvider;
import 'auditor_revisi_engine.dart';
import 'auth_provider.dart';

class AuditorExtRevisiStrategy implements AuditorRevisiStrategy {
  const AuditorExtRevisiStrategy(this._repo);

  final AuditorExtRepository _repo;

  @override
  bool get includeExtensionRefOnSave => true;

  @override
  Future<List<AuditorModel>> loadRevisiAuditors() =>
      _repo.getRevisiAuditorExt();

  @override
  Future<List<ExtDokumen>> loadRevisionDocuments(List<AuditorModel> selected) =>
      _repo.getDokumenRevisiAuditorExt(selected);

  @override
  Future<void> saveDocuments({
    required String latikRef,
    required List<AuditorRevisiBatch> batches,
  }) =>
      _repo.saveDokumenRevisiAuditorExt(
        latikRef: latikRef,
        batches: batches,
      );

  @override
  Future<void> requestVerification(List<AuditorModel> selected) =>
      _repo.requestVerifikasiRevisiAuditorExt(selected);
}

final auditorRevisiProvider = StateNotifierProvider.autoDispose<
    AuditorRevisiNotifier, AuditorRevisiState>((ref) {
  final user = ref.watch(authProvider).user;
  final latikRef = user?['latik_ref']?.toString() ?? '';
  return AuditorRevisiNotifier(
    strategy: AuditorExtRevisiStrategy(ref.watch(auditorExtRepoProvider)),
    latikRef: latikRef,
  );
});
