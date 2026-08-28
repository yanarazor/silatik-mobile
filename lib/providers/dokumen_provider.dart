import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/dokumen_model.dart';
import '../data/repositories/dokumen_repository.dart';
import '../data/services/dokumen_service.dart';
import 'auth_provider.dart';

final dokumenServiceProvider =
    Provider((ref) => DokumenService(ref.watch(dioProvider)));

final dokumenRepoProvider =
    Provider((ref) => DokumenRepository(ref.watch(dokumenServiceProvider)));

final dokumenListProvider = FutureProvider<List<DokumenModel>>((ref) async {
  return await ref.watch(dokumenRepoProvider).getDokumenList();
});
