import 'package:dio/dio.dart';
import 'dart:io';
import '../../core/constants/api_endpoints.dart';

class LatikService {
  final Dio _dio;
  LatikService(this._dio);

  // GET /api/latik/profile
  Future<Map<String, dynamic>> getProfile() async {
    final res = await _dio.get(ApiEndpoints.latikProfile);
    return res.data;
  }

  // GET /api/latik/checknib?nib={nib}
  Future<bool> checkNib(String nib) async {
    final res = await _dio
        .get(ApiEndpoints.latikCheckNib, queryParameters: {'nib': nib});
    return res.data['available'] ?? false;
  }

  // POST /api/latik/save
  Future<Map<String, dynamic>> saveLembaga(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.latikSave, data: data);
    return res.data;
  }

  // POST /api/latik/savedokumen (multipart)
  Future<void> saveDokumen({
    required String refLatik,
    required String idDokumenPendukung,
    required File file,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'ref_latik': refLatik,
      'id_dokumen_pendukung': idDokumenPendukung,
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    await _dio.post(ApiEndpoints.latikSaveDokumen, data: formData);
  }

  // GET /api/latik/dokumen/view
  Future<List<dynamic>> getDokumen() async {
    final res = await _dio.get(ApiEndpoints.latikGetDokumen);
    return res.data['data'] ?? res.data;
  }

  // GET /api/dokumen_pendukung/aktif → ambil template dokumen yg wajib diupload
  Future<List<dynamic>> getDokumenPendukungAktif() async {
    final res = await _dio.get(ApiEndpoints.dokumenPendukungAktif);
    return res.data['data'] ?? res.data;
  }

  // POST /api/latik/konfirmasidata
  Future<void> konfirmasiData(String refLatik) async {
    await _dio.post(ApiEndpoints.latikKonfirmasi, data: {
      'ref_latik': refLatik,
      'is_checked': true,
    });
  }

  // POST /api/latik/requestverifikasi
  Future<Map<String, dynamic>> requestVerifikasi(String refLatik) async {
    final res = await _dio.post(ApiEndpoints.latikRequestVerif, data: {
      'ref_latik': refLatik,
    });
    return res.data;
  }

  // GET /api/latik/listverifikasi
  Future<Map<String, dynamic>> getStatusVerifikasi() async {
    final res = await _dio.get(ApiEndpoints.latikListVerif);
    return res.data;
  }

  // GET /api/latik/str_latik
  Future<Map<String, dynamic>?> getSTR() async {
    final res = await _dio.get(ApiEndpoints.strLatik);
    return res.data;
  }

  // GET /api/latik/liststrinvoicelatik
  Future<List<dynamic>> getStrInvoiceList() async {
    final res = await _dio.get(ApiEndpoints.strListInvoiceLatik);
    return res.data['data'] ?? res.data;
  }

  // POST /api/latik/createinvoice
  Future<Map<String, dynamic>> createInvoice(String refLatik) async {
    final res = await _dio.post(ApiEndpoints.latikCreateInvoice, data: {
      'ref_latik': refLatik,
    });
    return res.data;
  }

  // GET /api/latik/search?q={query} (public)
  Future<List<dynamic>> searchLatik({String? query, String? provinsi}) async {
    final res = await _dio.get(ApiEndpoints.latikSearch, queryParameters: {
      if (query != null) 'q': query,
      if (provinsi != null) 'provinsi': provinsi,
    });
    return res.data['data'] ?? res.data;
  }

  // POST /api/latik/updateprofile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.latikUpdateProfile, data: data);
  }

  // POST /api/latik/pengalaman
  Future<void> savePengalaman(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.latikSavePengalaman, data: data);
  }

  // DELETE /api/latik/pengalaman/{ref}
  Future<void> deletePengalaman(String ref) async {
    await _dio.delete('${ApiEndpoints.latikDeletePengalaman}/$ref');
  }
}
