/// One training certificate attached to an auditor profile.
class AuditorCertificate {
  final String ref;
  final String nama;
  final String lembaga;
  final String tahun;
  final String fileUrl;

  const AuditorCertificate({
    this.ref = '',
    required this.nama,
    required this.lembaga,
    required this.tahun,
    required this.fileUrl,
  });

  factory AuditorCertificate.fromJson(Map<String, dynamic> json) {
    return AuditorCertificate(
      ref: (json['ref'] ?? json['id'] ?? '').toString(),
      nama: (json['nama_pelatihan'] ??
              json['nama'] ??
              json['nama_sertifikat'] ??
              '')
          .toString(),
      lembaga: (json['lembaga'] ?? json['issuer'] ?? '').toString(),
      tahun: (json['tahun'] ?? '').toString(),
      fileUrl: (json['sertifikat_file_url'] ??
              json['sertifikat_file'] ??
              json['file_url'] ??
              '')
          .toString(),
    );
  }

  bool get canDelete => ref.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'ref': ref,
        'nama': nama,
        'lembaga': lembaga,
        'tahun': tahun,
        'file_url': fileUrl,
      };
}