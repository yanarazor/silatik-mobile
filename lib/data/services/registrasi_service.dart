import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
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

    final payload = _extractMap(response.data);
    final refLatik = _stringValue(payload, 'ref') ??
        _stringValue(payload, 'latik_ref') ??
        _stringValue(payload, 'ref_latik');

    if (refLatik != null) {
      await _dio.post(ApiEndpoints.latikRequestVerif, data: {'ref_latik': refLatik});
    }

    return _stringValue(payload, 'nomor_referensi') ??
        _stringValue(payload, 'reference_number') ??
        _stringValue(payload, 'no_registrasi') ??
        refLatik ??
        'REG-${DateTime.now().millisecondsSinceEpoch}';
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final result = data['result'];
      if (result is Map<String, dynamic>) {
        final nested = result['data'];
        if (nested is Map<String, dynamic>) return nested;
        return result;
      }
      final nested = data['data'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    return const {};
  }

  String? _stringValue(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
