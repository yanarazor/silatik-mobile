import '../../core/utils/api_response_utils.dart';
import '../models/auditor_model.dart';
import '../models/registrasi_model.dart';
import '../services/auditor_payload.dart';
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

  /// Definisi Data Dukung (dengan nama `field` multipart) untuk create.
  Future<List<AuditorDokumenDef>> getDokumenDefs() async {
    final rows = await _service.loadAuditorDokumenDefs();
    return rows
        .whereType<Map>()
        .map((item) =>
            AuditorDokumenDef.fromJson(Map<String, dynamic>.from(item)))
        .where((d) => d.field.isNotEmpty)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Create auditor (Profil + Data Dukung) via multipart. Mengembalikan `ref`.
  Future<String> save(AuditorProfilPayload payload) async {
    final res = await _service.saveAuditor(await payload.toFormData());
    return pickString(extractMap(res), const ['ref', 'auditor_ref', 'ref_auditor']) ??
        pickString(res, const ['ref', 'auditor_ref', 'ref_auditor']) ??
        '';
  }

  /// Update auditor: kirim ref + hanya file dokumen yang berubah.
  Future<void> update(String ref, AuditorProfilPayload payload) async {
    await _service.updateAuditor(await payload.toFormData(ref: ref));
  }

  /// Simpan satu Sertifikasi Teknis untuk auditor [ref].
  Future<void> saveSertifikasiTeknis({
    required String refAuditor,
    required String namaPelatihan,
    required String tahun,
    required String lembaga,
    required FileItem sertifikatFile,
  }) async {
    final form = await buildSertifikasiTeknisFormData(
      refAuditor: refAuditor,
      namaPelatihan: namaPelatihan,
      tahun: tahun,
      lembaga: lembaga,
      sertifikatFile: sertifikatFile,
    );
    await _service.simpanSertifikasiTeknis(form);
  }

  Future<List<AuditorCertificate>> getSertifikasiTeknis(
      String refAuditor) async {
    final rows = await _service.getSertifikasiTeknis(refAuditor);
    return rows
        .whereType<Map>()
        .map((item) =>
            AuditorCertificate.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> deleteSertifikasiTeknis(String refSertifikat) =>
      _service.deleteSertifikasiTeknis(refSertifikat);

  Future<void> delete(String ref) => _service.deleteAuditor(ref);
}
