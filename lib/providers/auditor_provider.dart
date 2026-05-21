import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/auditor_model.dart';
import '../data/repositories/auditor_repository.dart';
import '../data/services/auditor_service.dart';
import 'auth_provider.dart';

class AuditorNotifier extends StateNotifier<List<AuditorModel>> {
  AuditorNotifier(this._repo) : super(const []);

  final AuditorRepository _repo;

  Future<void> load() async {
    state = await _repo.getAuditors();
  }

  void add(AuditorModel auditor) => state = [...state, auditor];
  void setAll(List<AuditorModel> auditors) => state = auditors;
  void update(AuditorModel auditor) => state = [for (final a in state) if (a.id == auditor.id) auditor else a];
  void remove(String id) => state = state.where((e) => e.id != id).toList();
}

final auditorServiceProvider = Provider((ref) => AuditorService(ref.watch(dioProvider)));
final auditorRepoProvider = Provider((ref) => AuditorRepository(ref.watch(auditorServiceProvider)));
final auditorProvider = StateNotifierProvider<AuditorNotifier, List<AuditorModel>>((ref) => AuditorNotifier(ref.watch(auditorRepoProvider)));
final auditorListProvider = FutureProvider<List<AuditorModel>>((ref) => ref.watch(auditorRepoProvider).getAuditors());
