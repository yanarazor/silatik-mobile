import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/utils/api_response_utils.dart';
import '../models/faq.dart';
import '../models/latik_profile.dart';
import '../models/user_profile.dart';

/// Keys under which the backend may expose the institution registration
/// number. The canonical field (per the web frontend `SelfLatikOrganization`
/// contract) is `no_pendaftaran`; the remaining entries are tolerated
/// fallbacks for older/variant responses.
const List<String> kRegistrationNumberKeys = [
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

/// Extracts a registration number from a latik profile [data] map, or returns
/// `null` when none is present. Never fabricates a value.
///
/// Resolution order:
/// 1. Any [kRegistrationNumberKeys] directly on [data].
/// 2. The same keys on the nested `o_latik` record (the real nesting key per
///    the web contract).
/// 3. The same keys on any row of an `exts` list.
///
/// Exposed as a top-level function so it can be unit-tested without a Dio
/// client or a [ProfileMenuService] instance.
String? extractRegistrationNumber(Map<String, dynamic> data) {
  String? scan(Map<String, dynamic> source) {
    for (final key in kRegistrationNumberKeys) {
      final value = meaningfulString(source[key]);
      if (value != null) return value;
    }
    return null;
  }

  final direct = scan(data);
  if (direct != null) return direct;

  final nested = data['o_latik'];
  if (nested is Map) {
    final fromNested = scan(Map<String, dynamic>.from(nested));
    if (fromNested != null) return fromNested;
  }

  final exts = data['exts'];
  if (exts is List) {
    for (final row in exts.whereType<Map>()) {
      final fromExt = scan(Map<String, dynamic>.from(row));
      if (fromExt != null) return fromExt;
    }
  }

  return null;
}

class ProfileMenuService {
  ProfileMenuService(this._dio);

  final Dio _dio;

  Future<LatikProfile> getLatikProfile({String? latikRef}) async {
    final userResponse = await _dio.get(ApiEndpoints.userMe);
    final user = extractMap(userResponse.data);
    final ref = _cleanText(latikRef) ?? _stringValue(user, 'latik_ref');

    final latikListResponse = await _dio.get(ApiEndpoints.latikList);
    final latikFromList =
        _findLatikByRef(extractList(latikListResponse.data), ref);

    final response = await _dio.get(ApiEndpoints.latikProfile);
    final profile = _extractLatikRecord(response.data, ref);

    if (ref == null || ref.isEmpty || _hasRegistrationNumber(profile)) {
      final merged = _mergePreferNonEmpty([
        _flattenLatikMap(user),
        latikFromList,
        profile,
      ]);
      return LatikProfile.fromJson(merged);
    }

    final viewResponse = await _dio.get('${ApiEndpoints.latikViewMain}/$ref');
    final merged = _mergePreferNonEmpty([
      _flattenLatikMap(user),
      latikFromList,
      profile,
      _extractLatikRecord(viewResponse.data, ref),
    ]);
    return LatikProfile.fromJson(merged);
  }

  Future<UserProfile> getUserProfile() async {
    final response = await _dio.get(ApiEndpoints.userMe);
    return UserProfile.fromJson(extractMap(response.data));
  }

  Future<List<Faq>> getFaqs() async {
    final response = await _dio.get(ApiEndpoints.faqs);
    return extractList(response.data)
        .whereType<Map>()
        .map((item) => Faq.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  bool _hasRegistrationNumber(Map<String, dynamic> data) {
    return extractRegistrationNumber(data) != null;
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
    final map = extractMap(data);
    final list = extractList(data);
    if (list.isNotEmpty) {
      final selected = _findLatikByRef(list, ref);
      return _flattenLatikMap(selected);
    }
    return _flattenLatikMap(map);
  }

  String? _stringValue(Map<String, dynamic> data, String key) =>
      meaningfulString(data[key]);

  String? _cleanText(String? value) => meaningfulString(value);

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

}
