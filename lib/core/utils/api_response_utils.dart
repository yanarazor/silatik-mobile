List<dynamic> extractList(dynamic data) {
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

Map<String, dynamic> extractMap(dynamic data) {
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

/// Nested map keys that latik/profile responses commonly wrap records under.
/// Used by [pickString]'s deep scan and mirrors the nesting the backend sends.
const List<String> _nestedRecordKeys = ['o_latik', 'latik', 'latik_data', 'str'];

/// Returns the first meaningful string found in [data] across [keys], or
/// [fallback] when none is present (defaults to `null`).
///
/// A value is "meaningful" when it is non-null and its trimmed string form is
/// neither empty nor the literal `"null"`. When [deep] is true and no direct
/// key matches, nested records under [_nestedRecordKeys] are scanned too.
String? pickString(
  Map<String, dynamic> data,
  List<String> keys, {
  bool deep = false,
  String? fallback,
}) {
  final direct = _scanKeys(data, keys);
  if (direct != null) return direct;

  if (deep) {
    for (final nestedKey in _nestedRecordKeys) {
      final nested = data[nestedKey];
      if (nested is Map) {
        final found = _scanKeys(Map<String, dynamic>.from(nested), keys);
        if (found != null) return found;
      }
    }
  }
  return fallback;
}

String? _scanKeys(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = meaningfulString(data[key]);
    if (value != null) return value;
  }
  return null;
}

/// Returns the trimmed string form of [value], or `null` when it is absent,
/// blank, or the literal string `"null"` (case-insensitive).
String? meaningfulString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
}

/// Coerces a dynamic [value] to an `int`, or returns `null` when it is absent,
/// blank, the literal `"null"`, or unparseable. Accepts `num` and numeric
/// strings.
int? parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  return int.tryParse(text);
}

/// Parses a dynamic [value] into a [DateTime]. Tries ISO-8601 first, then a
/// `dd-mm-yyyy` / `dd/mm/yyyy` fallback the backend sometimes sends. Returns
/// `null` when absent or unrecognized.
DateTime? parseFlexibleDate(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return null;

  final iso = DateTime.tryParse(text);
  if (iso != null) return iso;

  final match = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(text);
  if (match != null) {
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
      return DateTime(year, month, day);
    }
  }
  return null;
}
