import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/utils/api_response_utils.dart';
import '../models/dokumen_model.dart';

class DokumenService {
  final Dio _dio;
  DokumenService(this._dio);

  Future<List<DokumenModel>> getDokumenList() async {
    final res = await _dio.get(ApiEndpoints.dokumenAll);
    final list = extractList(res.data);
    return list
        .whereType<Map>()
        .map((item) => DokumenModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
