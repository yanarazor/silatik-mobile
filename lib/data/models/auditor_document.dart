import '../../core/utils/api_response_utils.dart';

/// One uploaded auditor document with verification status.
class AuditorDocument {
  final String id;
  final String nama;
  final String nomor;
  final String field;
  final int? statusVerifikasi;
  final String catatanVerifikasi;
  final String url;

  const AuditorDocument({
    required this.id,
    required this.nama,
    required this.nomor,
    required this.field,
    required this.statusVerifikasi,
    required this.catatanVerifikasi,
    required this.url,
  });

  factory AuditorDocument.fromJson(Map<String, dynamic> json) {
    final isi = json['isi'] is Map
        ? Map<String, dynamic>.from(json['isi'])
        : const <String, dynamic>{};
    final field = _pick(json, const ['field', 'kolom']);
    final urlKey = field.isEmpty ? null : 'url_$field';
    final sources = [
      isi,
      json,
      if (json['o_dokumen'] is Map)
        Map<String, dynamic>.from(json['o_dokumen']),
      if (isi['o_dokumen'] is Map) Map<String, dynamic>.from(isi['o_dokumen']),
    ];
    String first(String key) {
      for (final source in sources) {
        final raw = source[key];
        if (raw == null) continue;
        final text = raw.toString().trim();
        if (text.isNotEmpty && text != 'null') return text;
      }
      return '';
    }

    final url = (urlKey != null && first(urlKey).isNotEmpty)
        ? first(urlKey)
        : first('url_dokumen');

    return AuditorDocument(
      id: first('ref').isNotEmpty ? first('ref') : first('id'),
      nama: first('nama_dokumen').isNotEmpty ? first('nama_dokumen') : first('nama'),
      nomor: first('nomor'),
      field: field,
      statusVerifikasi: _toInt(first('status_verifikasi')),
      catatanVerifikasi: first('catatan_verifikasi').isNotEmpty
          ? first('catatan_verifikasi')
          : first('alasan_verifikasi'),
      url: url,
    );
  }

  static String _pick(Map<String, dynamic> data, List<String> keys) =>
      pickString(data, keys, fallback: '')!;

  static int? _toInt(String value) => parseInt(value);
}