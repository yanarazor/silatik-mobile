import '../models/latik_ext_model.dart';
import '../services/latik_service.dart';

class LatikExtRepository {
  LatikExtRepository(this._service);

  final LatikService _service;

  Future<ExtResolution?> resolve(String refLatik) async {
    final data = await _service.resolveExt(refLatik);
    return ExtResolution.fromResponse(data);
  }

  Future<List<ExtDokumen>> getDokumen(String refExt) async {
    final rows = await _service.getExtDokumen(refExt);
    return rows
        .whereType<Map>()
        .map((e) => ExtDokumen.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  Future<void> saveDokumen({
    required String refExt,
    required List<DokumenUpload> uploads,
  }) {
    return _service.saveExtDokumen(refExt: refExt, uploads: uploads);
  }

  Future<String> createInvoice(String refExt) =>
      _service.createExtInvoice(refExt);

  Future<void> requestVerifikasi(String refExt) =>
      _service.requestExtVerifikasi(refExt);

  Future<String> billing(String invoiceRef) => _service.getBilling(invoiceRef);

  Future<Map<String, dynamic>> checkBilling(String kodeTagihan) =>
      _service.checkBilling(kodeTagihan);
}
