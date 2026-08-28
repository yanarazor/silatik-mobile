import '../models/dokumen_model.dart';
import '../services/dokumen_service.dart';

class DokumenRepository {
  DokumenRepository(this._service);

  final DokumenService _service;

  Future<List<DokumenModel>> getDokumenList() => _service.getDokumenList();
}
