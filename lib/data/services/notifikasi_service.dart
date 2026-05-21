import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';

class NotifikasiService {
  NotifikasiService(this._dio);

  final Dio _dio;

  Future<List<dynamic>> getAll() async {
    final first = await _dio
        .get(ApiEndpoints.notificationAll, queryParameters: {'page': 1});
    final items = _extractList(first.data).toList();
    final totalPages = _extractTotalPages(first.data);
    if (totalPages > 1) {
      for (var page = 2; page <= totalPages; page++) {
        final res = await _dio
            .get(ApiEndpoints.notificationAll, queryParameters: {'page': page});
        items.addAll(_extractList(res.data));
      }
    }
    return items;
  }

  Future<List<dynamic>> getUnread() async {
    final response = await _dio.get(ApiEndpoints.notificationUnread);
    return _extractList(response.data);
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get(ApiEndpoints.notificationUnreadCount);
    final data = response.data;
    if (data is int) return data;
    if (data is Map<String, dynamic>) {
      final value =
          data['result'] ?? data['data'] ?? data['count'] ?? data['total'];
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }
    return 0;
  }

  Future<void> markAllAsRead() async {
    await _dio.get(ApiEndpoints.notificationMarkAllAsRead);
  }

  Future<void> markAsRead(String ref) async {
    await _dio.get('${ApiEndpoints.notificationMarkAsRead}/$ref');
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final result = data['result'];
      if (result is List) return result;
      if (result is Map<String, dynamic>) {
        if (result['data'] is List) return result['data'] as List;
        if (result['items'] is List) return result['items'] as List;
      }
      if (data['data'] is List) return data['data'] as List;
      if (data['items'] is List) return data['items'] as List;
    }
    return const [];
  }

  int _extractTotalPages(dynamic data) {
    if (data is Map<String, dynamic>) {
      final value = data['totalPages'] ?? data['total_pages'] ?? data['pages'];
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 1;
    }
    return 1;
  }
}
