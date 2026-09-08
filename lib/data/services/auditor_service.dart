import 'package:dio/dio.dart';
import 'dart:io';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/api_response_utils.dart';

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

  // POST /api/auditor/save
  Future<Map<String, dynamic>> saveAuditor(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.auditorSave, data: data);
    return res.data;
  }

  // POST /api/auditor/update
  Future<void> updateAuditor(Map<String, dynamic> data) async {
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

  // POST /api/auditor/simpansertifikasiteknis
  Future<void> simpanSertifikasiTeknis(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.auditorSimpanSertif, data: data);
  }

  // DELETE /api/auditor/sertifikasiteknis/{ref}
  Future<void> deleteSertifikasiTeknis(String ref) async {
    await _dio.delete('${ApiEndpoints.auditorDeleteSertif}/$ref');
  }

  // POST /api/auditor/penambahan/requestverifikasi
  Future<void> requestVerifikasiPenambahan(String refLatik) async {
    await _dio.post(ApiEndpoints.auditorRequestVerif, data: {
      'ref_latik': refLatik,
    });
  }
}
