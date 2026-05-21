import '../models/notifikasi_model.dart';
import '../services/notifikasi_service.dart';

class NotifikasiRepository {
  NotifikasiRepository(this._service);

  final NotifikasiService _service;

  Future<List<NotifikasiModel>> getList() async {
    final rows = await _service.getAll();
    return rows
        .whereType<Map>()
        .map((item) => NotifikasiModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<int> getUnreadCount() => _service.getUnreadCount();
  Future<void> markAllAsRead() => _service.markAllAsRead();
  Future<void> markAsRead(String ref) => _service.markAsRead(ref);
}
