import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/api_endpoints.dart';

class ProfileMenuService {
  ProfileMenuService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getLatikProfile({String? latikRef}) async {
    final userResponse = await _dio.get(ApiEndpoints.userMe);
    final user = _extractMap(userResponse.data);
    final ref = _cleanText(latikRef) ?? _stringValue(user, 'latik_ref');

    final latikListResponse = await _dio.get(ApiEndpoints.latikList);
    final latikFromList =
        _findLatikByRef(_extractList(latikListResponse.data), ref);

    final response = await _dio.get(ApiEndpoints.latikProfile);
    final profile = _extractLatikRecord(response.data, ref);

    if (ref == null || ref.isEmpty || _hasRegistrationNumber(profile)) {
      final merged = _mergePreferNonEmpty([
        _flattenLatikMap(user),
        latikFromList,
        profile,
      ]);
      return _ensureRegistrationNumber(merged);
    }

    final viewResponse = await _dio.get('${ApiEndpoints.latikViewMain}/$ref');
    final merged = _mergePreferNonEmpty([
      _flattenLatikMap(user),
      latikFromList,
      profile,
      _extractLatikRecord(viewResponse.data, ref),
    ]);
    return _ensureRegistrationNumber(merged);
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _dio.get(ApiEndpoints.userMe);
    return _extractMap(response.data);
  }

  Future<List<Map<String, dynamic>>> getFaqs() async {
    final response = await _dio.get(ApiEndpoints.faqs);
    return _extractList(response.data)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final result = data['result'];
      if (result is List) return result;
      if (result is Map<String, dynamic>) {
        if (result['data'] is List) return result['data'] as List;
        if (result['items'] is List) return result['items'] as List;
      }
      if (data['data'] is List) return data['data'] as List;
      if (data['items'] is List) return data['items'] as List;
    }
    return const [];
  }

  bool _hasRegistrationNumber(Map<String, dynamic> data) {
    return _findRegistrationNumber(data) != null;
  }

  Map<String, dynamic> _flattenLatikMap(Map<String, dynamic> data) {
    final nested = data['latik'] ??
        data['latik_data'] ??
        data['profile'] ??
        data['data_latik'] ??
        data['o_latik'];
    if (nested is Map) {
      return {
        ...data,
        ...Map<String, dynamic>.from(nested),
      };
    }
    return data;
  }

  Map<String, dynamic> _findLatikByRef(List<dynamic> rows, String? ref) {
    if (rows.isEmpty) return const {};
    final maps =
        rows.whereType<Map>().map((item) => Map<String, dynamic>.from(item));
    if (ref == null || ref.isEmpty) return maps.first;
    return maps.firstWhere(
      (item) =>
          _stringValue(item, 'ref') == ref ||
          _stringValue(item, 'latik_ref') == ref ||
          _stringValue(item, 'id') == ref,
      orElse: () => maps.first,
    );
  }

  Map<String, dynamic> _extractLatikRecord(dynamic data, String? ref) {
    final map = _extractMap(data);
    final list = _extractList(data);
    if (list.isNotEmpty) {
      final selected = _findLatikByRef(list, ref);
      return _flattenLatikMap(selected);
    }
    return _flattenLatikMap(map);
  }

  String? _stringValue(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty || text == 'null' ? null : text;
  }

  String? _cleanText(String? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text.toLowerCase() == 'null' ? null : text;
  }

  Map<String, dynamic> _mergePreferNonEmpty(List<Map<String, dynamic>> parts) {
    final merged = <String, dynamic>{};
    for (final part in parts) {
      part.forEach((key, value) {
        final incoming = _isMeaningful(value);
        final current = _isMeaningful(merged[key]);
        if (incoming || !current) {
          merged[key] = value;
        }
      });
    }
    return merged;
  }

  bool _isMeaningful(dynamic value) {
    if (value == null) return false;
    if (value is String) {
      final text = value.trim().toLowerCase();
      return text.isNotEmpty && text != 'null';
    }
    return true;
  }

  Map<String, dynamic> _ensureRegistrationNumber(Map<String, dynamic> data) {
    final reg = _findRegistrationNumber(data) ?? _generateRegistrationNumber();
    if (reg != null) {
      data['no_pendaftaran'] = reg;
      data['nomor_registrasi'] = reg;
      data['registration_number'] = reg;
    }
    if (kDebugMode) {
      const debugKeys = [
        'no_pendaftaran',
        'nomor_registrasi',
        'no_registrasi',
        'registration_number',
        'kode_registrasi',
        'kode_register',
        'no_register',
        'nomor_register',
        'registration_code',
        'no_urut_ext',
        'no_urut',
      ];
      final raw = {
        for (final key in debugKeys) key: data[key],
      };
      debugPrint('[LATIK] registration_number=$reg');
      debugPrint('[LATIK] registration raw values: $raw');
      debugPrint('[LATIK] available keys: ${data.keys.toList()}');
    }
    return data;
  }

  String? _generateRegistrationNumber() {
    const length = 13;
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(chars[rand.nextInt(chars.length)]);
    }
    return buffer.toString();
  }

  String? _findRegistrationNumber(Map<String, dynamic> data) {
    const keys = [
      'no_pendaftaran',
      'nomor_registrasi',
      'no_registrasi',
      'registration_number',
      'kode_registrasi',
      'kode_register',
      'no_register',
      'nomor_register',
      'registration_code',
      'no_urut_ext',
      'no_urut',
    ];
    for (final key in keys) {
      final direct = _stringValue(data, key);
      if (direct != null) return direct;
    }
    final exts = data['exts'];
    if (exts is List) {
      for (final row in exts.whereType<Map>()) {
        final item = Map<String, dynamic>.from(row);
        for (final key in keys) {
          final v = _stringValue(item, key);
          if (v != null) return v;
        }
      }
    }
    return null;
  }
}
