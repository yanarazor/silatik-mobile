class AuditorModel {
  final String id;
  final String nama;
  final String email;
  final String nik;
  final String tempatLahir;
  final DateTime? tanggalLahir;
  final String alamat;
  final String provinsi;
  final String kabupaten;
  final String kodePos;
  final String agama;
  final String phone;
  final String keterangan;
  final String fotoUrl;
  final String nomorSertifikasi;
  final String lembagaPenerbit;
  final DateTime? tanggalTerbit;
  final DateTime? tanggalBerakhir;
  final List<String> kompetensi;
  final List<AuditorCertificate> certificates;
  final String statusLabel;
  final String activeLabel;
  final String verificationLabel;
  final DateTime? strTanggalAkhir;
  final String filePath;
  final String fileName;
  final int fileSize;
  final String ktpFileUrl;
  final String sertifikatKompetensiUrl;
  final String portofolioUrl;
  final String praktikAuditUrl;
  final String asosiasiProfesiUrl;
  final String pernyataanIntegritasUrl;
  final String suratPermohonanUrl;
  final String pengangkatanUrl;

  const AuditorModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.nik,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.alamat,
    required this.provinsi,
    required this.kabupaten,
    required this.kodePos,
    required this.agama,
    required this.phone,
    required this.keterangan,
    required this.fotoUrl,
    required this.nomorSertifikasi,
    required this.lembagaPenerbit,
    required this.tanggalTerbit,
    required this.tanggalBerakhir,
    required this.kompetensi,
    required this.certificates,
    required this.statusLabel,
    required this.activeLabel,
    required this.verificationLabel,
    required this.strTanggalAkhir,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.ktpFileUrl,
    required this.sertifikatKompetensiUrl,
    required this.portofolioUrl,
    required this.praktikAuditUrl,
    required this.asosiasiProfesiUrl,
    required this.pernyataanIntegritasUrl,
    required this.suratPermohonanUrl,
    required this.pengangkatanUrl,
  });

  factory AuditorModel.fromJson(Map<String, dynamic> json) {
    final kompetensiRaw = json['kompetensi'] ??
        json['kompetensis'] ??
        json['keahlian'] ??
        json['scope'];
    final kompetensi = kompetensiRaw is List
        ? kompetensiRaw.map((e) => e.toString()).toList()
        : (kompetensiRaw
                ?.toString()
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList() ??
            <String>[]);

    final certificatesRaw = json['certificates'] ??
        json['sertifikat'] ??
        json['sertifikasi_teknis'];
    final certificates = certificatesRaw is List
        ? certificatesRaw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];
    final certModels = certificates
        .map(
          (item) => AuditorCertificate(
            nama: (item['nama_pelatihan'] ??
                    item['nama'] ??
                    item['nama_sertifikat'] ??
                    '')
                .toString(),
            lembaga: (item['lembaga'] ?? item['issuer'] ?? '').toString(),
            tahun: (item['tahun'] ?? '').toString(),
            fileUrl: (item['sertifikat_file_url'] ??
                    item['sertifikat_file'] ??
                    item['file_url'] ??
                    '')
                .toString(),
          ),
        )
        .where((c) => c.nama.isNotEmpty || c.fileUrl.isNotEmpty)
        .toList();
    final firstCert = certificates.isNotEmpty ? certificates.first : null;

    String pickCertValue(List<String> keys) {
      if (firstCert == null) return '';
      for (final key in keys) {
        final value = firstCert[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty && text != 'null') return text;
      }
      return '';
    }

    final certName = pickCertValue(
        const ['nama_pelatihan', 'nama', 'nama_sertifikat', 'title']);
    final certIssuer =
        pickCertValue(const ['lembaga', 'issuer', 'lembaga_penerbit']);
    final certFileUrl = pickCertValue(
        const ['sertifikat_file_url', 'sertifikat_file', 'file_url']);
    final certYear = pickCertValue(const ['tahun']);
    final certYearDate = _parseYear(certYear);

    final derivedKompetensi = kompetensi.isEmpty && certName.isNotEmpty
        ? certificates
            .map((item) => (item['nama_pelatihan'] ?? item['nama'] ?? '')
                .toString()
                .trim())
            .where((text) => text.isNotEmpty && text != 'null')
            .toList()
        : kompetensi;

    return AuditorModel(
      id: (json['ref'] ?? json['id'] ?? '').toString(),
      nama: (json['nama'] ?? json['name'] ?? json['nama_auditor'] ?? '')
          .toString(),
      email: (json['email'] ?? '').toString(),
      nik:
          (json['nik'] ?? json['identity_number'] ?? json['no_identitas'] ?? '')
              .toString(),
      tempatLahir:
          (json['tempat_lahir'] ?? json['birth_place'] ?? '').toString(),
      tanggalLahir: _parseDate(json['tanggal_lahir'] ?? json['birth_date']),
      alamat: (json['alamat'] ?? json['address'] ?? '').toString(),
      provinsi:
          (json['provinsi'] ?? json['province'] ?? json['nama_provinsi'] ?? '')
              .toString(),
      kabupaten: (json['kabupaten'] ??
              json['kota'] ??
              json['city'] ??
              json['nama_kabupaten'] ??
              '')
          .toString(),
      kodePos:
          (json['kode_post'] ?? json['kode_pos'] ?? json['postal_code'] ?? '')
              .toString(),
      agama: (json['agama'] ?? '').toString(),
      phone: (json['phone'] ?? json['telepon'] ?? '').toString(),
      keterangan: (json['keterangan'] ?? '').toString(),
      fotoUrl: (json['foto_url'] ?? json['foto'] ?? json['photo_url'] ?? '')
          .toString(),
      nomorSertifikasi: (json['nomor_sertifikasi'] ??
              json['no_sertifikat'] ??
              json['sertifikat'] ??
              certName ??
              '')
          .toString(),
      lembagaPenerbit:
          (json['lembaga_penerbit'] ?? json['issuer'] ?? certIssuer ?? '')
              .toString(),
      tanggalTerbit: _parseDate(
              json['tanggal_terbit'] ?? json['terbit'] ?? json['issued_at']) ??
          certYearDate,
      tanggalBerakhir: _parseDate(
          json['tanggal_berakhir'] ?? json['berakhir'] ?? json['expired_at']),
      kompetensi: derivedKompetensi,
      certificates: certModels,
      statusLabel: _statusLabel(json['status']),
      activeLabel: _activeLabel(json['status_aktif'] ?? json['active']),
      verificationLabel: _verificationLabel(json['status_verifikasi']),
      strTanggalAkhir: _parseDate(json['str_tanggal_akhir']),
      filePath:
          (json['file_path'] ?? json['path'] ?? certFileUrl ?? '').toString(),
      fileName: (json['file_name'] ?? json['filename'] ?? '').toString(),
      fileSize:
          int.tryParse((json['file_size'] ?? json['size'] ?? 0).toString()) ??
              0,
      ktpFileUrl: (json['ktp_file'] ?? '').toString(),
      sertifikatKompetensiUrl:
          (json['sertifikat_kompetensi_file'] ?? '').toString(),
      portofolioUrl: (json['portofolio'] ?? '').toString(),
      praktikAuditUrl: (json['praktik_audit_file'] ?? '').toString(),
      asosiasiProfesiUrl: (json['asosiasi_profesi_file'] ?? '').toString(),
      pernyataanIntegritasUrl:
          (json['pernyataan_integritas_file'] ?? '').toString(),
      suratPermohonanUrl: (json['surat_permohonan_file'] ?? '').toString(),
      pengangkatanUrl: (json['pengangkatan_file'] ?? '').toString(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static DateTime? _parseYear(String? value) {
    if (value == null) return null;
    final year = int.tryParse(value.trim());
    if (year == null) return null;
    return DateTime(year, 1, 1);
  }

  static String _statusLabel(dynamic status) {
    final code = int.tryParse((status ?? '').toString());
    if (code == 1) return 'Auditor TIK Tetap';
    return 'Auditor TIK Tidak Tetap';
  }

  static String _activeLabel(dynamic active) {
    final code = int.tryParse((active ?? '').toString());
    if (code == 1) return 'Aktif';
    return 'Tidak Aktif';
  }

  static String _verificationLabel(dynamic statusVerifikasi) {
    final code = int.tryParse((statusVerifikasi ?? '').toString());
    if (code == 1) return 'Sudah Verifikasi';
    return 'Belum Verifikasi';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'email': email,
        'nik': nik,
        'tempat_lahir': tempatLahir,
        'tanggal_lahir': tanggalLahir?.toIso8601String(),
        'alamat': alamat,
        'provinsi': provinsi,
        'kabupaten': kabupaten,
        'kode_pos': kodePos,
        'agama': agama,
        'phone': phone,
        'keterangan': keterangan,
        'foto_url': fotoUrl,
        'nomor_sertifikasi': nomorSertifikasi,
        'lembaga_penerbit': lembagaPenerbit,
        'tanggal_terbit': tanggalTerbit?.toIso8601String(),
        'tanggal_berakhir': tanggalBerakhir?.toIso8601String(),
        'kompetensi': kompetensi,
        'certificates': certificates.map((item) => item.toJson()).toList(),
        'status': statusLabel,
        'active': activeLabel,
        'status_verifikasi': verificationLabel,
        'str_tanggal_akhir': strTanggalAkhir?.toIso8601String(),
        'file_path': filePath,
        'file_name': fileName,
        'file_size': fileSize,
        'ktp_file': ktpFileUrl,
        'sertifikat_kompetensi_file': sertifikatKompetensiUrl,
        'portofolio': portofolioUrl,
        'praktik_audit_file': praktikAuditUrl,
        'asosiasi_profesi_file': asosiasiProfesiUrl,
        'pernyataan_integritas_file': pernyataanIntegritasUrl,
        'surat_permohonan_file': suratPermohonanUrl,
        'pengangkatan_file': pengangkatanUrl,
      };
}

class AuditorCertificate {
  final String nama;
  final String lembaga;
  final String tahun;
  final String fileUrl;

  const AuditorCertificate({
    required this.nama,
    required this.lembaga,
    required this.tahun,
    required this.fileUrl,
  });

  Map<String, dynamic> toJson() => {
        'nama': nama,
        'lembaga': lembaga,
        'tahun': tahun,
        'file_url': fileUrl,
      };
}
