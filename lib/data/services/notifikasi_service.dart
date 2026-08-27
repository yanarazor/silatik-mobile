import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/utils/api_response_utils.dart';

class NotifikasiPageResult<T> {
  const NotifikasiPageResult({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int totalPages;
  final int total;
}

class NotifikasiService {
  NotifikasiService(this._dio);

  final Dio _dio;

  Future<NotifikasiPageResult<dynamic>> getPage({int page = 1}) async {
    final response = await _dio.get(
      ApiEndpoints.notificationAll,
      queryParameters: {'page': page},
    );
    return _extractPage(response.data);
  }

  Future<NotifikasiPageResult<dynamic>> getUnreadPage({int page = 1}) async {
    final response = await _dio.get(
      ApiEndpoints.notificationUnread,
      queryParameters: {'page': page},
    );
    return _extractPage(response.data);
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get(ApiEndpoints.notificationUnreadCount);
    final data = response.data;
    if (data is int) return data;
    if (data is Map<String, dynamic>) {
      final value =
          data['result'] ?? data['data'] ?? data['count'] ?? data['total'];
      if (value is int) return value;
      if (value is Map) {
        final nested = value['unread'] ?? value['count'] ?? value['total'];
        if (nested is int) return nested;
        return int.tryParse(nested?.toString() ?? '') ?? 0;
      }
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

  NotifikasiPageResult<dynamic> _extractPage(dynamic data) {
    return NotifikasiPageResult<dynamic>(
      items: extractList(data),
      page: _extractInt(data, const ['page', 'current_page'], fallback: 1),
      totalPages: _extractTotalPages(data),
      total: _extractInt(
          data, const ['totalData', 'total_data', 'total'],
          fallback: 0),
    );
  }

  int _extractTotalPages(dynamic data) {
    if (data is Map<String, dynamic>) {
      final value = data['totalPages'] ?? data['total_pages'] ?? data['pages'];
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 1;
    }
    return 1;
  }

  int _extractInt(dynamic data, List<String> keys, {required int fallback}) {
    if (data is Map<String, dynamic>) {
      for (final key in keys) {
        final value = data[key];
        if (value is int) return value;
        final parsed = int.tryParse(value?.toString() ?? '');
        if (parsed != null) return parsed;
      }
    }
    return fallback;
  }
}
