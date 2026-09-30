import '../../core/utils/api_response_utils.dart';

class LatikExperience {
  final int? id;
  final String ref;
  final String tahun;
  final String ippdPengguna;
  final String objectAudit;

  const LatikExperience({
    this.id,
    this.ref = '',
    this.tahun = '',
    this.ippdPengguna = '',
    this.objectAudit = '',
  });

  factory LatikExperience.fromJson(Map<String, dynamic> json) =>
      LatikExperience(
        id: parseInt(json['id']),
        ref: pickString(json, const ['ref'], fallback: '')!,
        tahun: pickString(json, const ['tahun'], fallback: '')!,
        ippdPengguna: pickString(json, const ['ippd_pengguna'], fallback: '')!,
        objectAudit: pickString(json, const ['object_audit'], fallback: '')!,
      );

  bool get canEdit => ref.isNotEmpty;

  Map<String, dynamic> toPayload() => {
        if (id != null) 'id': id,
        if (ref.isNotEmpty) 'ref': ref,
        'tahun': tahun,
        'ippd_pengguna': ippdPengguna,
        'object_audit': objectAudit,
      };
}
