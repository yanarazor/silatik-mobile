import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/utils/api_response_utils.dart';
import '../models/master_data_model.dart';

class MasterDataService {
  MasterDataService(this._dio);

  final Dio _dio;

  Future<List<ProvinsiModel>> getProvinsi() async {
    final response = await _dio.get(ApiEndpoints.provinsi);
    final items = extractList(response.data);
    return items
        .whereType<Map>()
        .map((e) => ProvinsiModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<KabupatenModel>> getKabupaten({String? provinsiId}) async {
    final queryParameters = <String, dynamic>{};
    if (provinsiId != null && provinsiId.isNotEmpty) {
      queryParameters['id'] = provinsiId;
    }
    final response = await _dio.get(
      ApiEndpoints.kabupaten,
      queryParameters: queryParameters,
    );
    final items = extractList(response.data);
    return items
        .whereType<Map>()
        .map((e) => KabupatenModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
