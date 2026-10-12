import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/utils/api_response_utils.dart';
import '../models/slider.dart';

class SliderService {
  SliderService(this._dio);

  final Dio _dio;

  Future<List<SliderItem>> getLandingSliders() async {
    final response = await _dio.get(ApiEndpoints.sliderLanding);
    return extractList(response.data)
        .whereType<Map>()
        .map((item) => SliderItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
