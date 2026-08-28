import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/master_data_model.dart';
import '../data/repositories/master_data_repository.dart';
import '../data/services/master_data_service.dart';
import 'auth_provider.dart';

final masterDataServiceProvider =
    Provider((ref) => MasterDataService(ref.watch(dioProvider)));

final masterDataRepoProvider = Provider(
    (ref) => MasterDataRepository(ref.watch(masterDataServiceProvider)));

final provinsiListProvider =
    FutureProvider.autoDispose<List<ProvinsiModel>>((ref) async {
  final repo = ref.watch(masterDataRepoProvider);
  return repo.getProvinsi();
});

final kabupatenListProvider =
    FutureProvider.autoDispose.family<List<KabupatenModel>, String?>((ref, provinsiId) async {
  if (provinsiId == null || provinsiId.isEmpty) {
    return [];
  }
  final repo = ref.watch(masterDataRepoProvider);
  return repo.getKabupaten(provinsiId: provinsiId);
});
