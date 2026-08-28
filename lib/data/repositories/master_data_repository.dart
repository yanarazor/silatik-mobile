import '../models/master_data_model.dart';
import '../services/master_data_service.dart';

class MasterDataRepository {
  MasterDataRepository(this._service);

  final MasterDataService _service;

  Future<List<ProvinsiModel>> getProvinsi() => _service.getProvinsi();

  Future<List<KabupatenModel>> getKabupaten({String? provinsiId}) =>
      _service.getKabupaten(provinsiId: provinsiId);
}
