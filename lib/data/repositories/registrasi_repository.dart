import '../models/registrasi_model.dart';
import '../services/registrasi_service.dart';

class RegistrasiRepository {
  RegistrasiRepository(this._service);

  final RegistrasiService _service;

  Future<String> submit(RegistrasiModel data) => _service.submit(data);
}
