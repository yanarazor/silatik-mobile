import '../models/auditor_model.dart';
import '../services/auditor_service.dart';

class AuditorRepository {
  AuditorRepository(this._service);

  final AuditorService _service;

  Future<List<AuditorModel>> getAuditors() async {
    final rows = await _service.getAuditorsByLatik();
    return rows
        .whereType<Map>()
        .map((item) => AuditorModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<AuditorModel?> getDetail(String ref) async {
    final data = await _service.getAuditorDetail(ref);
    final payload = data['result'] ?? data['data'] ?? data;
    if (payload is! Map) return null;
    return AuditorModel.fromJson(Map<String, dynamic>.from(payload));
  }

  Future<List<AuditorDocument>> getDocuments(String ref) async {
    final rows = await _service.getAuditorDocuments(ref);
    return rows
        .whereType<Map>()
        .map(
            (item) => AuditorDocument.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Map<String, dynamic>> save(Map<String, dynamic> data) =>
      _service.saveAuditor(data);
  Future<void> update(Map<String, dynamic> data) =>
      _service.updateAuditor(data);
  Future<void> delete(String ref) => _service.deleteAuditor(ref);
}
