import '../../core/utils/api_response_utils.dart';

/// One auditor supporting-document definition (GET /auditor/dokumen/view).
class AuditorDokumenDef {
  final String id;
  final String namaDokumen;
  final String field;
  final bool fileRequired;
  final int order;

  const AuditorDokumenDef({
    required this.id,
    required this.namaDokumen,
    required this.field,
    required this.fileRequired,
    required this.order,
  });

  factory AuditorDokumenDef.fromJson(Map<String, dynamic> json) {
    return AuditorDokumenDef(
      id: (json['id'] ?? '').toString(),
      namaDokumen: (json['nama_dokumen'] ?? json['nama'] ?? '').toString(),
      field: (json['field'] ?? json['kolom'] ?? '').toString(),
      fileRequired: parseInt(json['file_required']) != 0,
      order: parseInt(json['order']) ?? 0,
    );
  }
}