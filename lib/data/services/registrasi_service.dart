import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/utils/api_response_utils.dart';
import '../models/registrasi_model.dart';

class RegistrasiService {
  RegistrasiService(this._dio);

  final Dio _dio;

  Future<String> submit(RegistrasiModel data) async {
    final lembaga = data.lembaga;
    if (lembaga == null) {
      throw StateError('Data lembaga belum lengkap');
    }

    final response = await _dio.post(ApiEndpoints.latikSave, data: {
      ...lembaga.toJson(),
      'nomor_kan': data.nomorKan,
      'tanggal_terbit_kan': data.terbitKan?.toIso8601String(),
      'tanggal_berakhir_kan': data.berakhirKan?.toIso8601String(),
      'ruang_lingkup': data.ruangLingkup,
    });

    final payload = extractMap(response.data);
    final refLatik =
        pickString(payload, const ['ref', 'latik_ref', 'ref_latik']);

    if (refLatik != null) {
      await _dio.post(ApiEndpoints.latikRequestVerif, data: {'ref_latik': refLatik});
    }

    return pickString(payload,
            const ['nomor_referensi', 'reference_number', 'no_registrasi']) ??
        refLatik ??
        'REG-${DateTime.now().millisecondsSinceEpoch}';
  }
}
