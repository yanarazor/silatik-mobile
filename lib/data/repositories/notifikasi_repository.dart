import '../models/notifikasi_model.dart';
import '../services/notifikasi_service.dart';

class NotifikasiRepository {
  NotifikasiRepository(this._service);

  final NotifikasiService _service;

  Future<NotifikasiPageResult<NotifikasiModel>> getPage({int page = 1}) async {
    return _mapPage(await _service.getPage(page: page));
  }

  Future<NotifikasiPageResult<NotifikasiModel>> getUnreadPage(
      {int page = 1}) async {
    return _mapPage(await _service.getUnreadPage(page: page));
  }

  NotifikasiPageResult<NotifikasiModel> _mapPage(
      NotifikasiPageResult<dynamic> result) {
    return NotifikasiPageResult<NotifikasiModel>(
      items: result.items
          .whereType<Map>()
          .map((item) =>
              NotifikasiModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      page: result.page,
      totalPages: result.totalPages,
      total: result.total,
    );
  }

  Future<int> getUnreadCount() => _service.getUnreadCount();
  Future<void> markAllAsRead() => _service.markAllAsRead();
  Future<void> markAsRead(String ref) => _service.markAsRead(ref);
}
