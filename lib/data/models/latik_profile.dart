import '../../core/utils/api_response_utils.dart';
import 'profil_dokumen.dart';

/// Typed model of the merged LATIK profile (from `/latik/profile`,
/// `/latik/view/{ref}`, `/latik` and `/user/me`). Ported from the web
/// frontend `SelfLatikOrganization` contract, extended with the alternate
/// key spellings the mobile backend responses use.
///
/// `fromJson` owns all key-variant resolution and `o_latik`/nested-record
/// lookup, so UI code reads typed getters instead of scanning raw maps.
class LatikProfile {
  final String namaLatik;
  final String noPendaftaran;
  final String noNib;
  final String noNpwp;
  final String noSiup;
  final String noStr;
  final String email;
  final String phone;
  final String website;
  final String alamat;
  final String provinsi;
  final String kabupaten;
  final String kodePos;
  final String badanHukum;
  final String latitude;
  final String longitude;
  final String jmlAuditor;
  final String areaOperasional;

  /// Raw status text/codes as sent by the backend, used by the screens to
  /// derive display badges. Empty when absent.
  final String namaStatus;
  final String namaStatusStr;
  final String statusVerifikasi;
  final String strStatus;

  final DateTime? strTanggalAwal;
  final DateTime? strTanggalAkhir;

  /// Institution ref used by update/edit calls.
  final String latikRef;

  /// KAN accreditation status text, and whether any KAN certificate/number
  /// is present.
  final String akreditasiKanStatus;
  final bool hasKanCertificate;

  /// Number of auditors reported by the profile payload (0 when absent; the
  /// screen falls back to the auditor list length).
  final int auditorCount;

  /// Display value for KAN accreditation: the status text, else 'Terdaftar'
  /// when a certificate is present, else '-'.
  String get akreditasiValue {
    if (akreditasiKanStatus.isNotEmpty) return akreditasiKanStatus;
    return hasKanCertificate ? 'Terdaftar' : '-';
  }

  /// Raw registration-scope source (`lingkup_pendaftaran` and variants),
  /// passed to `latikScopeLabels` for display. Dynamic because it may be a
  /// map or list depending on the endpoint.
  final Object? scopeSource;

  /// Uploaded completeness documents from `dokumen_kelengkapan`.
  final List<ProfilDokumen> documents;

  /// The raw merged response map. Retained for data-layer transforms that need
  /// fields beyond the typed surface (e.g. registration form pre-fill reading
  /// per-document file URLs). UI code should use the typed getters, not this.
  final Map<String, dynamic> raw;

  const LatikProfile({
    this.namaLatik = '',
    this.noPendaftaran = '',
    this.noNib = '',
    this.noNpwp = '',
    this.noSiup = '',
    this.noStr = '',
    this.email = '',
    this.phone = '',
    this.website = '',
    this.alamat = '',
    this.provinsi = '',
    this.kabupaten = '',
    this.kodePos = '',
    this.badanHukum = '',
    this.latitude = '',
    this.longitude = '',
    this.jmlAuditor = '',
    this.areaOperasional = '',
    this.namaStatus = '',
    this.namaStatusStr = '',
    this.statusVerifikasi = '',
    this.strStatus = '',
    this.strTanggalAwal,
    this.strTanggalAkhir,
    this.latikRef = '',
    this.akreditasiKanStatus = '',
    this.hasKanCertificate = false,
    this.auditorCount = 0,
    this.scopeSource,
    this.documents = const [],
    this.raw = const {},
  });

  factory LatikProfile.fromJson(Map<String, dynamic> json) {
    String get(List<String> keys) =>
        pickString(json, keys, deep: true, fallback: '')!;

    return LatikProfile(
      namaLatik: get(const [
        'nama_latik',
        'nama_latik_perusahaan',
        'name',
        'nama',
        'first_name',
      ]),
      noPendaftaran: get(const [
        'no_pendaftaran',
        'nomor_registrasi',
        'no_registrasi',
        'registration_number',
        'kode_registrasi',
      ]),
      noNib: get(const ['no_nib', 'nib', 'nomor_nib', 'no_nib_latik']),
      noNpwp: get(const ['no_npwp', 'npwp', 'nomor_npwp']),
      noSiup: get(const ['no_siup', 'siup', 'nomor_siup']),
      noStr: get(const ['no_str', 'nomor_str', 'str_number']),
      email: get(const ['email', 'email_latik', 'email_institusi']),
      phone: get(const ['phone', 'telepon', 'no_telepon']),
      website: get(const ['website', 'situs', 'url']),
      alamat: get(const [
        'alamat_latik',
        'alamat',
        'address',
        'alamat_perusahaan',
      ]),
      provinsi: get(const [
        'nama_provinsi',
        'provinsi',
        'province_name',
        'provinsi_alamat_latik',
        'province',
      ]),
      kabupaten: get(const [
        'nama_kabupaten',
        'kota',
        'city_name',
        'kabupaten_alamat_latik',
        'kabupaten',
        'city',
      ]),
      kodePos: get(const ['kode_pos', 'postal_code']),
      badanHukum: get(const ['badan_hukum', 'legal_entity_type']),
      latitude: get(const ['latitude', 'lat']),
      longitude: get(const ['longitude', 'lng', 'lon']),
      jmlAuditor: get(const ['jml_auditor', 'jumlah_auditor']),
      areaOperasional: get(const ['area_operasional', 'area']),
      namaStatus: get(const ['nama_status']),
      namaStatusStr: get(const ['nama_status_str', 'status_str']),
      statusVerifikasi: get(const [
        'status_verifikasi',
        'status',
        'status_latik',
        'verification_status',
      ]),
      strStatus: get(const ['str_status', 'status_aktif_str']),
      strTanggalAwal: parseFlexibleDate(
          pickString(json, const ['str_tanggal_awal'], deep: true)),
      strTanggalAkhir: parseFlexibleDate(
          pickString(json, const ['str_tanggal_akhir'], deep: true)),
      latikRef: get(const ['ref', 'latik_ref', 'ref_latik']),
      akreditasiKanStatus: get(const [
        'nama_status_kan',
        'status_akreditasi_kan',
        'status_kan',
        'akreditasi_kan',
        'status_akreditasi',
      ]),
      hasKanCertificate: get(const [
        'nomor_kan',
        'no_kan',
        'nomor_sertifikat_kan',
        'nomor_sertifikat',
        'file_cer_kan',
        'file_kan',
        'sertifikat_kan',
        'file_sertifikat_kan',
        'ruang_lingkup_kan',
        'ruang_lingkup_akreditasi',
      ]).isNotEmpty,
      auditorCount: parseInt(pickString(
              json,
              const [
                'jumlah_auditor',
                'total_auditor',
                'jumlah',
                'total_auditors',
                'auditor_count',
                'jml_auditor',
              ],
              deep: true)) ??
          0,
      scopeSource: json['lingkup_pendaftaran'] ??
          json['ruang_lingkup_latik'] ??
          json['ruang_lingkup'] ??
          json['scope'],
      documents: ProfilDokumen.listFrom(json),
      raw: json,
    );
  }

  /// True when the profile carries no meaningful institution data.
  bool get isEmpty =>
      namaLatik.isEmpty &&
      noNib.isEmpty &&
      email.isEmpty &&
      alamat.isEmpty;

  /// Best available human status text (nama_status → nama_status_str →
  /// status_verifikasi), or '' when none present. Screens apply their own
  /// fallback label.
  String get statusText {
    for (final s in [namaStatus, namaStatusStr, statusVerifikasi]) {
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  /// True when the status text reads as verified/active.
  bool get isVerified {
    final s = statusText.toLowerCase();
    return s.contains('terverifikasi') ||
        s.contains('sudah verifikasi') ||
        s.contains('aktif') ||
        s.contains('approved');
  }

  /// Combined "alamat, kabupaten, provinsi [kodePos]" address line.
  String get fullAddress {
    final parts =
        [alamat, kabupaten, provinsi].where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    final joined = parts.join(', ');
    return kodePos.isEmpty ? joined : '$joined $kodePos';
  }
}
