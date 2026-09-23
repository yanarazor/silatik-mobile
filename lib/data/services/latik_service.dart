import 'package:dio/dio.dart';
import 'dart:io';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/api_response_utils.dart';
import 'auditor_ext_payload.dart';

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

  Future<void> saveDokumenBatch(List<DokumenUpload> uploads) async {
    final map = <String, dynamic>{};
    for (final u in uploads) {
      final file = u.file;
      map['file_${u.id}'] = file != null
          ? await MultipartFile.fromFile(file.path, filename: u.fileName)
          : 'undefined';
      map['nomor_${u.id}'] = u.nomor ?? '';
      if (u.tanggal != null && u.tanggal!.isNotEmpty) {
        map['tanggal_${u.id}'] = u.tanggal;
      }
    }
    await _dio.post(ApiEndpoints.latikSaveDokumen, data: FormData.fromMap(map));
  }

  // GET /api/latik/dokumen/view
  Future<List<dynamic>> getDokumen() async {
    final res = await _dio.get(ApiEndpoints.latikGetDokumen);
    return res.data['data'] ?? res.data;
  }

  // GET /api/dokumen_pendukung/aktif → fetch required document templates
  Future<List<dynamic>> getDokumenPendukungAktif() async {
    final res = await _dio.get(ApiEndpoints.dokumenPendukungAktif);
    return res.data['data'] ?? res.data;
  }

  // POST /api/latik/konfirmasidata — body {is_checked: 1}. Marks
  // org data as confirmed; backend resolves LATIK from token.
  Future<void> konfirmasiData() async {
    await _dio.post(ApiEndpoints.latikKonfirmasi, data: {'is_checked': 1});
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

  // GET /api/latik/listinvoices?status=&jenis_transaksi=
  // Backend scopes to the authenticated LATIK; empty params = no filter.
  Future<List<dynamic>> getInvoices({int? status, int? jenisTransaksi}) async {
    final res = await _dio.get(
      ApiEndpoints.latikListInvoices,
      queryParameters: {
        'status': status?.toString() ?? '',
        'jenis_transaksi': jenisTransaksi?.toString() ?? '',
      },
    );
    return extractList(res.data);
  }

  // POST /api/latik/createinvoice (multipart) — INITIAL REGISTRATION mode
  // (is_new=1). `auditor` = JSON string of selected auditors.
  // Returns invoice `ref`.
  Future<String> createRegistrationInvoice(
      List<LatikRegAuditorItem> auditors) async {
    final res = await _dio.post(
      ApiEndpoints.latikCreateInvoice,
      data: buildLatikRegistrationInvoiceFormData(auditors: auditors),
    );
    return pickString(extractMap(res.data), const ['ref'], fallback: '') ?? '';
  }

  // GET /api/latik/search?q={query} (public)
  Future<List<dynamic>> searchLatik({String? query, String? provinsi}) async {
    final res = await _dio.get(ApiEndpoints.latikSearch, queryParameters: {
      if (query != null) 'q': query,
      if (provinsi != null) 'provinsi': provinsi,
    });
    return res.data['data'] ?? res.data;
  }

  // POST /api/latik/saveprofile — self-service LATIK profile update.
  // Body is the full profile JSON (see save-latik-profile contract).
  Future<void> saveProfile(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.latikSaveProfile, data: data);
  }

  // POST /api/latik/pengalaman
  Future<void> savePengalaman(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.latikSavePengalaman, data: data);
  }

  // DELETE /api/latik/pengalaman/{ref}
  Future<void> deletePengalaman(String ref) async {
    await _dio.delete('${ApiEndpoints.latikDeletePengalaman}/$ref');
  }

  // ---------------------------------------------------------- EXTENSION

  // POST /api/latikext — resolve/create extension reference for this LATIK.
  Future<Map<String, dynamic>> resolveExt(String refLatik) async {
    final res = await _dio.post(ApiEndpoints.latikExt, data: {
      'ref_latik': refLatik,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  // GET /api/latikext/dokumen/view?ref_ext=
  Future<List<dynamic>> getExtDokumen(String refExt) async {
    final res = await _dio.get(
      ApiEndpoints.latikExtGetDokumen,
      queryParameters: {'ref_ext': refExt},
    );
    return extractList(res.data);
  }

  // POST /api/latikext/savedokumen (multipart) — sama pola dengan
  // [saveDokumenBatch]: key dinamis `file_{id}` / `nomor_{id}` / `tanggal_{id}`,
  // TANGGAL FORMAT `DD-MM-YYYY` (pemanggil yang memformat). Endpoint ini
  // "replace full state" seperti savedokumen LATIK, jadi WAJIB mengirim SEMUA
  // dokumen. File tak berubah dikirim string "undefined" (backend pertahankan).
  // Bedanya dari base: ada `ref_ext` di body dan nomor/tanggal per dokumen.
  Future<void> saveExtDokumen({
    required String refExt,
    required List<DokumenUpload> uploads,
  }) async {
    final map = <String, dynamic>{'ref_ext': refExt};
    for (final u in uploads) {
      final file = u.file;
      map['file_${u.id}'] = file != null
          ? await MultipartFile.fromFile(file.path, filename: u.fileName)
          : 'undefined';
      map['nomor_${u.id}'] = u.nomor ?? '';
      if (u.tanggal != null && u.tanggal!.isNotEmpty) {
        map['tanggal_${u.id}'] = u.tanggal;
      }
    }
    await _dio.post(ApiEndpoints.latikExtSaveDokumen,
        data: FormData.fromMap(map));
  }

  // POST /api/latik/createinvoice (multipart) — extension mode.
  // `is_new=2` marks an extension; therefore `latik_ext` must be included,
  // `auditor` is sent as an empty list for the LATIK flow. Returns invoice `ref`.
  Future<String> createExtInvoice(String refExt) async {
    final res = await _dio.post(
      ApiEndpoints.latikCreateInvoice,
      data: FormData.fromMap({
        'is_new': '2',
        'auditor': '{"auditor":[]}',
        'latik_ext': refExt,
      }),
    );
    return pickString(extractMap(res.data), const ['ref'], fallback: '') ?? '';
  }

  // POST /api/latikext/requestverifikasi?ref_ext= — empty body.
  Future<void> requestExtVerifikasi(String refExt) async {
    await _dio.post(
      ApiEndpoints.latikExtRequestVerifikasi,
      queryParameters: {'ref_ext': refExt},
    );
  }

  // ---------------------------------------------------------------- BILLING

  // GET /api/latik/billing?ref=&ref_invoice= — hasilkan/ambil kode tagihan.
  // `ref` = ref_latik pemilik invoice (spec §5), `ref_invoice` = ref invoice.
  // [refLatik] opsional demi kompatibilitas pemanggil lama; bila null jatuh ke
  // [invoiceRef] (perilaku sebelumnya).
  // Kembalikan kode_tagihan ('' bila belum ada).
  Future<String> getBilling(String invoiceRef, {String? refLatik}) async {
    final res = await _dio.get(
      ApiEndpoints.latikBilling,
      queryParameters: {
        'ref': (refLatik == null || refLatik.isEmpty) ? invoiceRef : refLatik,
        'ref_invoice': invoiceRef,
      },
    );
    return pickString(extractMap(res.data), const ['kode_tagihan'],
            fallback: '') ??
        '';
  }

  // GET /api/latik/checkbilling?kode_tagihan= — poll status kode billing.
  // Kembalikan envelope agar pemanggil bisa memeriksa "siap/belum".
  Future<Map<String, dynamic>> checkBilling(String kodeTagihan) async {
    final res = await _dio.get(
      ApiEndpoints.latikCheckBilling,
      queryParameters: {'kode_tagihan': kodeTagihan},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}

class DokumenUpload {
  final int id;
  final File? file;
  final String? fileName;
  final String? nomor;
  final String? tanggal;

  const DokumenUpload({
    required this.id,
    this.file,
    this.fileName,
    this.nomor,
    this.tanggal,
  });
}
