import '../../core/utils/api_response_utils.dart';

enum ExtAction {
  proceed,
  inVerification,
  returned,
  publishingStr,
}

/// Branching based on `status`:
///   0 → proceed (fresh / editable)
///   1 → inVerification
///   2 → returned
///   3 → publishingStr
class ExtResolution {
  final String refExt;
  final int status;
  final String noStr;

  const ExtResolution({
    required this.refExt,
    required this.status,
    this.noStr = '',
  });

  static ExtResolution? fromResponse(dynamic data) {
    final list = extractList(data);
    if (list.isEmpty) return null;
    final first = list.first;
    if (first is! Map) return null;
    final map = Map<String, dynamic>.from(first);
    final refExt = meaningfulString(map['ref_ext']);
    if (refExt == null) return null;
    return ExtResolution(
      refExt: refExt,
      status: parseInt(map['status']) ?? 0,
      noStr: meaningfulString(map['no_str']) ?? '',
    );
  }

  ExtAction get action => switch (status) {
        1 => ExtAction.inVerification,
        2 => ExtAction.returned,
        3 => ExtAction.publishingStr,
        _ => ExtAction.proceed, // 0 dan nilai tak dikenal → lanjut wizard.
      };
}

class ExtDokumen {
  final int id;
  final String namaDokumen;
  final bool nomorRequired;
  final bool tanggalRequired;
  final bool fileRequired;

  final String nomor;
  final String tanggal;
  final String fileUrl;

  const ExtDokumen({
    required this.id,
    required this.namaDokumen,
    required this.nomorRequired,
    required this.tanggalRequired,
    required this.fileRequired,
    this.nomor = '',
    this.tanggal = '',
    this.fileUrl = '',
  });

  factory ExtDokumen.fromJson(Map<String, dynamic> json) {
    final isi = json['isi'] is Map
        ? Map<String, dynamic>.from(json['isi'])
        : const <String, dynamic>{};
    return ExtDokumen(
      id: parseInt(json['id']) ?? 0,
      namaDokumen:
          meaningfulString(json['nama_dokumen']) ?? meaningfulString(json['nama']) ?? '',
      nomorRequired: parseInt(json['nomor_required']) == 1,
      tanggalRequired: parseInt(json['tanggal_required']) == 1,
      fileRequired: parseInt(json['file_required']) == 1,
      nomor: meaningfulString(isi['nomor']) ?? '',
      tanggal: meaningfulString(isi['tanggal']) ?? '',
      fileUrl: meaningfulString(isi['url_dokumen']) ??
          meaningfulString(isi['file']) ??
          '',
    );
  }
}
