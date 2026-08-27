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
