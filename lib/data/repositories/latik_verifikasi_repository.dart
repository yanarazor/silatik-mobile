import '../services/auditor_ext_payload.dart';
import '../services/latik_service.dart';

class LatikVerifikasiRepository {
  LatikVerifikasiRepository(this._service);

  final LatikService _service;

  Future<void> saveDokumen(List<DokumenUpload> uploads) =>
      _service.saveDokumenBatch(uploads);

  Future<String> createInvoice(List<LatikRegAuditorItem> auditors) =>
      _service.createRegistrationInvoice(auditors);

  Future<void> konfirmasiData() => _service.konfirmasiData();

  Future<void> requestVerifikasi(String refLatik) =>
      _service.requestVerifikasi(refLatik);

  Future<String> billing(String invoiceRef, {String? refLatik}) =>
      _service.getBilling(invoiceRef, refLatik: refLatik);

  Future<Map<String, dynamic>> checkBilling(String kodeTagihan) =>
      _service.checkBilling(kodeTagihan);
}
