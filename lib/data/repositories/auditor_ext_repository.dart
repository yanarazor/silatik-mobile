import '../models/latik_ext_model.dart';
import '../services/auditor_ext_payload.dart';
import '../services/auditor_service.dart';

class AuditorExtRepository {
  AuditorExtRepository(this._service);

  final AuditorService _service;

  Future<ExtResolution?> resolve(String refLatik) async {
    final data = await _service.resolveExt(refLatik);
    return ExtResolution.fromResponse(data);
  }

  Future<void> saveSelection({
    required String latikRef,
    required String latikExt,
    required List<String> auditorRefs,
  }) {
    return _service.saveExtSelection(
      latikRef: latikRef,
      latikExt: latikExt,
      auditorRefs: auditorRefs,
    );
  }

  Future<List<ExtDokumen>> getDokumen(
    String refExt,
    List<String> refAuditors,
  ) async {
    final rows = await _service.getExtDokumen(refExt, refAuditors);
    return rows
        .whereType<Map>()
        .map((e) => ExtDokumen.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  Future<void> saveDokumen({
    required String latikRef,
    required String latikExt,
    required List<AuditorExtBatch> batches,
  }) {
    return _service.saveExtDokumen(
      latikRef: latikRef,
      latikExt: latikExt,
      batches: batches,
    );
  }

  Future<String> createInvoice({
    required String latikRef,
    required String latikExt,
    required List<AuditorExtInvoiceItem> auditors,
  }) {
    return _service.createExtInvoice(
      latikRef: latikRef,
      latikExt: latikExt,
      auditors: auditors,
    );
  }

  Future<void> requestVerifikasi(String refExt) =>
      _service.requestExtVerifikasi(refExt);
}
