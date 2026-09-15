import '../../core/utils/api_response_utils.dart';

/// Satu dokumen kelengkapan LATIK dari array `dokumen_kelengkapan`
/// di dalam response GET /latik/profile.
///
/// Bentuk record bervariasi: terkadang field ada langsung di item, terkadang
/// dibungkus `isi`, dan nama dokumen yang dipakai untuk tampil ada di
/// `jenis_dokumen` / `o_dokumen.nama_dokumen` (nama top-level adalah nama
/// file hasil unggah). Nilai diambil dari urutan sumber yang paling relevan.
class ProfilDokumen {
  final String nama;
  final String nomor;
  final String tanggal;
  final String url;
  final String catatan;
  final int? statusVerifikasi; // 1 = terverifikasi, selain itu = belum

  final int? id;
  final bool nomorRequired;
  final bool tanggalRequired;
  final bool fileRequired;

  const ProfilDokumen({
    this.nama = '',
    this.nomor = '',
    this.tanggal = '',
    this.url = '',
    this.catatan = '',
    this.statusVerifikasi,
    this.id,
    this.nomorRequired = false,
    this.tanggalRequired = false,
    this.fileRequired = false,
  });

  bool get terverifikasi => statusVerifikasi == 1;

  factory ProfilDokumen.fromJson(Map<String, dynamic> json) {
    final isi = json['isi'] is Map
        ? Map<String, dynamic>.from(json['isi'])
        : const <String, dynamic>{};
    final template = _mapOrNull(json['o_dokumen']) ??
        _mapOrNull(isi['o_dokumen']);
    // Data record diutamakan; template hanya sebagai cadangan nama.
    final records = [
      if (isi.isNotEmpty) isi,
      json,
    ];
    final sources = [
      ...records,
      if (template != null) template,
    ];

    String first(List<String> keys) {
      for (final source in sources) {
        for (final key in keys) {
          final raw = source[key];
          if (raw == null) continue;
          final text = raw.toString().trim();
          if (text.isNotEmpty && text != 'null') return text;
        }
      }
      return '';
    }

    // Nama tampil: `jenis_dokumen` record, lalu nama template `o_dokumen`;
    // top-level `nama_dokumen` hanyalah nama file unggah, dipakai terakhir
    // sebagai fallback (response versi lama tanpa field lain).
    var nama = first(const ['jenis_dokumen', 'nama', 'name', 'dokumen']);
    if (nama.isEmpty && template != null) {
      nama = _pick(template, const ['nama_dokumen', 'nama', 'name']);
    }
    if (nama.isEmpty) {
      nama = _pick(json, const ['nama_dokumen']);
    }
    // ponytail: backend mengirim nama dengan \r\n di tengah; ratakan jadi spasi
    nama = nama.replaceAll(RegExp(r'\s+'), ' ').trim();

    return ProfilDokumen(
      nama: nama,
      nomor: first(const ['nomor', 'nomor_dokumen']),
      tanggal: first(const ['tanggal', 'tanggal_dokumen']),
      url: first(const ['url_dokumen']).isNotEmpty
          ? first(const ['url_dokumen'])
          : _dynamicUrlField(records),
      catatan: first(const ['catatan_verifikasi', 'alasan_verifikasi']),
      statusVerifikasi: _toInt(first(const ['status_verifikasi'])),
    );
  }

  /// Mengambil semua record dari map profil /latik/profile.
  static List<ProfilDokumen> listFrom(Map<String, dynamic> profile) {
    final raw = _findList(profile, 'dokumen_kelengkapan');
    if (raw == null) return const [];
    final docs = <ProfilDokumen>[];
    for (final item in raw.whereType<Map>()) {
      final doc = ProfilDokumen.fromJson(Map<String, dynamic>.from(item));
      final kosong = doc.nama.isEmpty &&
          doc.nomor.isEmpty &&
          doc.tanggal.isEmpty &&
          doc.url.isEmpty;
      if (!kosong) docs.add(doc);
    }
    return docs;
  }

  static List<ProfilDokumen> listFromView(List<dynamic> rows) {
    final indexed = <MapEntry<int, ProfilDokumen>>[];
    for (final item in rows.whereType<Map>()) {
      final map = Map<String, dynamic>.from(item);
      final base = ProfilDokumen.fromJson(map);
      final isi = _mapOrNull(map['isi']) ?? const {};
      final template = _mapOrNull(isi['o_dokumen']);
      var nama = _pick(isi, const ['jenis_dokumen']);
      if (nama.isEmpty && template != null) {
        nama = _pick(template, const ['nama_dokumen']);
      }
      if (nama.isEmpty) {
        nama = _stripLeadingNumber(_pick(map, const ['nama_dokumen']));
      }
      final doc = ProfilDokumen(
        nama: nama.replaceAll(RegExp(r'\s+'), ' ').trim(),
        nomor: base.nomor,
        tanggal: base.tanggal,
        url: base.url,
        catatan: base.catatan,
        statusVerifikasi: base.statusVerifikasi,
        id: _toInt(_pick(map, const ['id'])),
        nomorRequired: _toInt(_pick(map, const ['nomor_required'])) == 1,
        tanggalRequired: _toInt(_pick(map, const ['tanggal_required'])) == 1,
        fileRequired: _toInt(_pick(map, const ['file_required'])) == 1,
      );
      final order = _toInt(_pick(map, const ['order'])) ?? indexed.length;
      indexed.add(MapEntry(order, doc));
    }
    indexed.sort((a, b) => a.key.compareTo(b.key));
    return indexed.map((e) => e.value).toList();
  }

  // "1. Salinan akta badan hukum" -> "Salinan akta badan hukum"
  static String _stripLeadingNumber(String name) => name
      .replaceFirst(RegExp(r'^\s*\d+\.\s*'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static List<dynamic>? _findList(Map<String, dynamic> data, String key) {
    final direct = data[key];
    if (direct is List) return direct;
    // ponytail: hanya telusuri satu level; map profil sudah diflatten service
    for (final nestedKey in const [
      'latik',
      'latik_data',
      'data_latik',
      'o_latik',
      'profile',
    ]) {
      final nested = data[nestedKey];
      if (nested is Map) {
        final inner = nested[key];
        if (inner is List) return inner;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _mapOrNull(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

  static String _pick(Map<String, dynamic> data, List<String> keys) =>
      pickString(data, keys, fallback: '')!;

  // Backend kadang memakai key dinamis `url_<field>` untuk file tiap dokumen.
  static String _dynamicUrlField(List<Map<String, dynamic>> sources) {
    for (final source in sources) {
      for (final entry in source.entries) {
        if (!entry.key.startsWith('url_')) continue;
        final raw = entry.value;
        if (raw == null) continue;
        final text = raw.toString().trim();
        if (text.isNotEmpty && text != 'null') return text;
      }
    }
    return '';
  }

  static int? _toInt(String value) {
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }
}
