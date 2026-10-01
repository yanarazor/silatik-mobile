import '../models/auditor_model.dart';
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

  // --------------------------------------------------------------- REVISI

  Future<List<AuditorModel>> getRevisiAuditorExt() async {
    final rows = await _service.getRevisiAuditorExt();
    return rows
        .whereType<Map>()
        .map((row) => AuditorModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<AuditorModel>> getRevisiAddAuditor() async {
    final rows = await _service.getRevisiAddAuditor();
    return rows
        .whereType<Map>()
        .map((row) => AuditorModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<ExtDokumen>> getDokumenRevisiAuditorExt(
    List<AuditorModel> auditors,
  ) async {
    final payload = <Map<String, String>>[];
    for (final auditor in auditors) {
      final refExt = auditor.auditorExt
          .map((extension) => extension.latikExt)
          .firstWhere((ref) => ref.isNotEmpty, orElse: () => '');
      if (auditor.id.isEmpty || refExt.isEmpty) {
        throw FormatException(
          'Missing auditor or extension reference for ${auditor.nama}',
        );
      }
      payload.add({'ref_ext': refExt, 'ref_auditor': auditor.id});
    }
    return _parseRevisionDocuments(
      await _service.getDokumenRevisiAuditorExt(payload),
    );
  }

  Future<List<ExtDokumen>> getDokumenRevisiAddAuditor(
    List<AuditorModel> auditors,
  ) async {
    final payload = [
      for (final auditor in auditors)
        if (auditor.id.isNotEmpty) {'ref_auditor': auditor.id},
    ];
    if (payload.length != auditors.length) {
      throw const FormatException(
          'A selected auditor is missing its reference');
    }
    return _parseRevisionDocuments(
      await _service.getDokumenRevisiAddAuditor(payload),
    );
  }

  List<ExtDokumen> _parseRevisionDocuments(List<dynamic> rows) => rows
      .whereType<Map>()
      .map((row) => ExtDokumen.fromJson(Map<String, dynamic>.from(row)))
      .toList()
    ..sort((a, b) => a.id.compareTo(b.id));

  Future<void> saveDokumenRevisiAuditorExt({
    required String latikRef,
    required List<AuditorRevisiBatch> batches,
  }) =>
      _service.saveDokumenRevisiAuditorExt(
        latikRef: latikRef,
        batches: batches,
      );

  Future<void> saveDokumenRevisiAddAuditor({
    required String latikRef,
    required List<AuditorRevisiBatch> batches,
  }) =>
      _service.saveDokumenRevisiAddAuditor(
        latikRef: latikRef,
        batches: batches,
      );

  Future<void> requestVerifikasiRevisiAuditorExt(
    List<AuditorModel> auditors,
  ) {
    final payload = <Map<String, String>>[];
    for (final auditor in auditors) {
      final refExt = auditor.auditorExt
          .map((extension) => extension.latikExt)
          .firstWhere((ref) => ref.isNotEmpty, orElse: () => '');
      if (auditor.id.isEmpty || refExt.isEmpty) {
        throw FormatException(
          'Missing auditor or extension reference for ${auditor.nama}',
        );
      }
      payload.add({'ref_ext': refExt, 'ref_auditor': auditor.id});
    }
    return _service.requestVerifikasiRevisiAuditorExt(payload);
  }

  Future<void> requestVerifikasiRevisiAddAuditor(
    List<AuditorModel> auditors,
  ) {
    final payload = [
      for (final auditor in auditors)
        if (auditor.id.isNotEmpty) {'ref_auditor': auditor.id},
    ];
    if (payload.length != auditors.length) {
      throw const FormatException(
          'A selected auditor is missing its reference');
    }
    return _service.requestVerifikasiRevisiAddAuditor(payload);
  }

  // ------------------------------------------------------------ PENAMBAHAN

  /// Buat invoice penambahan (is_new=3). Kembalikan `ref` invoice.
  Future<String> createAddInvoice(List<AuditorAddInvoiceItem> auditors) =>
      _service.createAddInvoice(auditors);

  /// Ajukan verifikasi penambahan untuk satu auditor.
  Future<void> requestVerifikasiPenambahan(String refAuditor) =>
      _service.requestVerifikasiPenambahan(refAuditor);
}
