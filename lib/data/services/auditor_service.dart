import 'package:dio/dio.dart';
import 'dart:io';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/api_response_utils.dart';
import 'auditor_ext_payload.dart';

class AuditorService {
  final Dio _dio;
  AuditorService(this._dio);

  // GET /api/latik/auditors
  Future<List<dynamic>> getAuditorsByLatik() async {
    final res = await _dio.get(ApiEndpoints.auditorsByLatik);
    return extractList(res.data);
  }

  // GET /api/latik/auditor/view/{ref}
  Future<Map<String, dynamic>> getAuditorDetail(String ref) async {
    final res = await _dio.get('${ApiEndpoints.auditorView}/$ref');
    return Map<String, dynamic>.from(res.data as Map);
  }

  // POST /api/auditor/dokumen/view (tanpa ref) → daftar definisi Data Dukung.
  // Dipakai saat create untuk tahu nama field multipart tiap dokumen.
  Future<List<dynamic>> loadAuditorDokumenDefs() async {
    final res = await _dio.post(ApiEndpoints.auditorDokumenView);
    return extractList(res.data);
  }

  // POST /api/auditor/save (multipart). [data] boleh Map atau FormData.
  Future<Map<String, dynamic>> saveAuditor(Object data) async {
    final res = await _dio.post(ApiEndpoints.auditorSave, data: data);
    return Map<String, dynamic>.from(res.data as Map);
  }

  // POST /api/auditor/update (multipart). [data] boleh Map atau FormData.
  Future<void> updateAuditor(Object data) async {
    await _dio.post(ApiEndpoints.auditorUpdate, data: data);
  }

  // DELETE /api/auditor/{ref}
  Future<void> deleteAuditor(String ref) async {
    await _dio.delete('${ApiEndpoints.auditorDelete}/$ref');
  }

  // POST /api/auditor/dokumen/view?ref={ref}
  Future<List<dynamic>> getAuditorDocuments(String ref) async {
    final res = await _dio.post(
      ApiEndpoints.auditorDokumenView,
      queryParameters: {'ref': ref},
    );
    return extractList(res.data);
  }

  // POST /api/auditor/savedokumen (multipart)
  Future<void> saveDokumenAuditor({
    required String refAuditor,
    required File file,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'ref_auditor': refAuditor,
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    await _dio.post(ApiEndpoints.auditorSaveDokumen, data: formData);
  }

  // GET /api/auditor/sertifikasiteknis/{ref_auditor} → list of certificates.
  Future<List<dynamic>> getSertifikasiTeknis(String refAuditor) async {
    final res =
        await _dio.get('${ApiEndpoints.auditorGetSertif}/$refAuditor');
    return extractList(res.data);
  }

  // POST /api/auditor/simpansertifikasiteknis (multipart). [data] boleh Map
  // atau FormData.
  Future<void> simpanSertifikasiTeknis(Object data) async {
    await _dio.post(ApiEndpoints.auditorSimpanSertif, data: data);
  }

  // DELETE /api/auditor/sertifikasiteknis/{ref}
  Future<void> deleteSertifikasiTeknis(String ref) async {
    await _dio.delete('${ApiEndpoints.auditorDeleteSertif}/$ref');
  }

  // POST /api/auditor/penambahan/requestverifikasi — sekali per auditor.
  Future<void> requestVerifikasiPenambahan(String refAuditor) async {
    await _dio.post(ApiEndpoints.auditorRequestVerif, data: {
      'ref_auditor': refAuditor,
    });
  }

  // POST /api/latik/createinvoice (multipart) — mode penambahan (is_new=3).
  // Kembalikan `ref` invoice.
  Future<String> createAddInvoice(List<AuditorAddInvoiceItem> auditors) async {
    final form =
        await buildAuditorAddCreateInvoiceFormData(auditors: auditors);
    final res = await _dio.post(ApiEndpoints.latikCreateInvoice, data: form);
    return pickString(extractMap(res.data), const ['ref'], fallback: '') ?? '';
  }

  // ---------------------------------------------------------- PERPANJANGAN

  // POST /api/latikext-auditor — resolve/buat referensi perpanjangan auditor.
  // Envelope sama bentuk dengan /latikext (ExtResolution.fromResponse parse).
  Future<Map<String, dynamic>> resolveExt(String refLatik) async {
    final res = await _dio.post(ApiEndpoints.auditorExtResolve, data: {
      'ref_latik': refLatik,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  // POST /api/auditorext — simpan pilihan auditor untuk perpanjangan.
  Future<void> saveExtSelection({
    required String latikRef,
    required String latikExt,
    required List<String> auditorRefs,
  }) async {
    await _dio.post(ApiEndpoints.auditorExt, data: {
      'latik_ref': latikRef,
      'latik_ext': latikExt,
      'auditors': [
        for (final ref in auditorRefs) {'auditor_ref': ref},
      ],
    });
  }

  // GET /api/auditorext/dokumen/view?ref_ext=&ref_auditors=<csv>
  // Respons: satu array flat untuk semua auditor (lihat AUDITOR_EXT_DOKUMEN).
  Future<List<dynamic>> getExtDokumen(
    String refExt,
    List<String> refAuditors,
  ) async {
    final res = await _dio.get(
      ApiEndpoints.auditorExtGetDokumen,
      queryParameters: {
        'ref_ext': refExt,
        'ref_auditors': refAuditors.join(','),
      },
    );
    return extractList(res.data);
  }

  // POST /api/auditorext/savedokumen (multipart, notasi array bersarang).
  Future<void> saveExtDokumen({
    required String latikRef,
    required String latikExt,
    required List<AuditorExtBatch> batches,
  }) async {
    final form = await buildAuditorExtSaveDokumenFormData(
      latikRef: latikRef,
      latikExt: latikExt,
      batches: batches,
    );
    await _dio.post(ApiEndpoints.auditorExtSaveDokumen, data: form);
  }

  // POST /api/auditorext/createinvoice (multipart). Kembalikan `ref` invoice.
  Future<String> createExtInvoice({
    required String latikRef,
    required String latikExt,
    required List<AuditorExtInvoiceItem> auditors,
  }) async {
    final form = await buildAuditorExtCreateInvoiceFormData(
      latikRef: latikRef,
      latikExt: latikExt,
      auditors: auditors,
    );
    final res =
        await _dio.post(ApiEndpoints.auditorExtCreateInvoice, data: form);
    return pickString(extractMap(res.data), const ['ref'], fallback: '') ?? '';
  }

  // POST /api/auditorext/requestverifikasi?latik_ext= — body kosong.
  Future<void> requestExtVerifikasi(String refExt) async {
    await _dio.post(
      ApiEndpoints.auditorExtRequestVerifikasi,
      queryParameters: {'latik_ext': refExt},
    );
  }
}
