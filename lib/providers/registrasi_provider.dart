import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/api_response_utils.dart';
import '../data/models/auditor_model.dart';
import '../data/models/lembaga_model.dart';
import '../data/models/registrasi_model.dart';
import '../data/repositories/auditor_repository.dart';
import '../data/repositories/registrasi_repository.dart';
import '../data/services/latik_service.dart';
import '../data/services/profile_menu_service.dart';
import '../data/services/registrasi_service.dart';
import 'auditor_provider.dart';
import 'auth_provider.dart';
import 'profile_menu_provider.dart';

class RegistrasiState {
  final RegistrasiModel data;
  final int step;
  final bool isSubmitting;
  final String? referenceNumber;

  const RegistrasiState(
      {this.data = const RegistrasiModel(),
      this.step = 0,
      this.isSubmitting = false,
      this.referenceNumber});

  RegistrasiState copyWith(
      {RegistrasiModel? data,
      int? step,
      bool? isSubmitting,
      String? referenceNumber}) {
    return RegistrasiState(
      data: data ?? this.data,
      step: step ?? this.step,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      referenceNumber: referenceNumber ?? this.referenceNumber,
    );
  }
}

class RegistrasiNotifier extends StateNotifier<RegistrasiState> {
  RegistrasiNotifier(this._repo, this._profileMenuService, this._latikService,
      this._auditorRepo)
      : super(const RegistrasiState());

  final RegistrasiRepository _repo;
  final ProfileMenuService _profileMenuService;
  final LatikService _latikService;
  final AuditorRepository _auditorRepo;
  bool _initializedFromApi = false;

  void setStep(int step) => state = state.copyWith(step: step);
  void setLembaga(LembagaModel model) =>
      state = state.copyWith(data: state.data.copyWith(lembaga: model));
  void setAkreditasi(
      {required String nomor,
      required DateTime terbit,
      required DateTime berakhir,
      required List<String> ruangLingkup,
      required FileItem file}) {
    state = state.copyWith(
        data: state.data.copyWith(
            nomorKan: nomor,
            terbitKan: terbit,
            berakhirKan: berakhir,
            ruangLingkup: ruangLingkup,
            sertifikatKan: file));
  }

  void setDocument(String key, FileItem? file) {
    final docs = Map<String, FileItem?>.from(state.data.dokumen);
    docs[key] = file;
    state = state.copyWith(data: state.data.copyWith(dokumen: docs));
  }

  void setAuditors(List<AuditorModel> auditors) =>
      state = state.copyWith(data: state.data.copyWith(auditors: auditors));
  void setPernyataan(bool v) =>
      state = state.copyWith(data: state.data.copyWith(pernyataan: v));

  Future<void> submit() async {
    state = state.copyWith(isSubmitting: true);
    try {
      final refNum = await _repo.submit(state.data);
      state = state.copyWith(isSubmitting: false, referenceNumber: refNum);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }

  Future<void> initializeFromApi({String? latikRef}) async {
    if (_initializedFromApi) return;

    final profile =
        await _profileMenuService.getLatikProfile(latikRef: latikRef);
    final dokumen = await _mapDocuments(profile);
    final akreditasi = _mapAkreditasi(profile);
    final auditors = await _auditorRepo.getAuditors();

    state = state.copyWith(
      data: state.data.copyWith(
        lembaga: _mapLembaga(profile),
        dokumen: dokumen,
        nomorKan: akreditasi.nomor ?? state.data.nomorKan,
        terbitKan: akreditasi.terbit ?? state.data.terbitKan,
        berakhirKan: akreditasi.berakhir ?? state.data.berakhirKan,
        ruangLingkup: akreditasi.ruangLingkup.isNotEmpty
            ? akreditasi.ruangLingkup
            : state.data.ruangLingkup,
        sertifikatKan: akreditasi.file ?? state.data.sertifikatKan,
        auditors: auditors,
      ),
    );

    _initializedFromApi = true;
  }

  LembagaModel _mapLembaga(Map<String, dynamic> p) {
    String value(List<String> keys) {
      for (final key in keys) {
        final raw = p[key];
        if (raw == null) continue;
        final text = raw.toString().trim();
        if (text.isNotEmpty && text != 'null') return text;
      }
      return '';
    }

    return LembagaModel(
      nama:
          value(const ['nama_latik', 'nama_latik_perusahaan', 'name', 'nama']),
      nib: value(const ['no_nib', 'nib', 'nomor_nib']),
      badanHukum: value(const ['badan_hukum', 'legal_entity_type']),
      alamat: value(const ['alamat_latik', 'alamat', 'address']),
      provinsi: _normalizeProvince(
          value(const ['nama_provinsi', 'provinsi_name', 'provinsi'])),
      kota: value(const ['nama_kabupaten', 'city_name', 'kabupaten', 'kota']),
      kodePos: value(const ['kode_pos', 'postal_code']),
      telepon: value(const ['telepon', 'phone']),
      email: value(const ['email', 'email_latik']),
      website: value(const ['website']),
    );
  }

  Future<Map<String, FileItem?>> _mapDocuments(
      Map<String, dynamic> profile) async {
    final docs = <String, FileItem?>{
      'nib_bkpm': _fileFromUrl(_pickValue(profile, const ['file_nib'])),
      'struktur_manajemen': _fileFromUrl(_pickValue(profile,
          const ['file_struktur_organiassi', 'file_struktur_organisasi'])),
      'profil_latik':
          _fileFromUrl(_pickValue(profile, const ['file_profi_latik'])),
    };

    var rows = await _latikService.getDokumen();
    if (rows.isEmpty && profile['dokumen_kelengkapan'] is List) {
      rows = profile['dokumen_kelengkapan'] as List;
    }
    for (final item in rows.whereType<Map>()) {
      final map = Map<String, dynamic>.from(item);
      final isi = map['isi'] is Map
          ? Map<String, dynamic>.from(map['isi'])
          : const <String, dynamic>{};
      final fileUrl = _pickValue(isi, const [
            'url_dokumen',
            'file',
            'path',
            'url',
            'file_url',
            'url_filename'
          ]) ??
          _pickValue(map, const [
            'url_dokumen',
            'file',
            'path',
            'url',
            'file_url',
            'url_filename'
          ]);
      if (fileUrl == null || fileUrl.isEmpty) continue;
      final label = _pickValue(isi, const [
            'nama_dokumen',
            'nama',
            'name',
            'dokumen',
            'jenis_dokumen'
          ])?.toLowerCase() ??
          _pickValue(map, const [
            'nama_dokumen',
            'nama',
            'name',
            'dokumen',
            'jenis_dokumen'
          ])?.toLowerCase() ??
          _pickValue(Map<String, dynamic>.from(isi['o_dokumen'] ?? {}),
              const ['nama_dokumen', 'nama', 'name'])?.toLowerCase() ??
          _pickValue(Map<String, dynamic>.from(map['o_dokumen'] ?? {}),
              const ['nama_dokumen', 'nama', 'name'])?.toLowerCase() ??
          '';

      if (label.contains('akta')) {
        docs['akta_badan_hukum'] ??= _fileFromUrl(fileUrl);
      } else if (label.contains('pengurus') || label.contains('sk')) {
        docs['ikatan_kerja_auditor'] ??= _fileFromUrl(fileUrl);
      } else if (label.contains('akreditasi') ||
          label.contains('kan') ||
          label.contains('iso')) {
        docs['surat_akreditasi_kan'] ??= _fileFromUrl(fileUrl);
      } else if (label.contains('nib') || label.contains('bkpm')) {
        docs['nib_bkpm'] ??= _fileFromUrl(fileUrl);
      } else if (label.contains('struktur')) {
        docs['struktur_manajemen'] ??= _fileFromUrl(fileUrl);
      } else if (label.contains('profil')) {
        docs['profil_latik'] ??= _fileFromUrl(fileUrl);
      } else if (label.contains('tupoksi') ||
          (label.contains('tugas') && label.contains('pokok')) ||
          label.contains('fungsi')) {
        docs['peraturan_tupoksi'] ??= _fileFromUrl(fileUrl);
      } else if (label.contains('permohonan') && label.contains('auditor')) {
        docs['permohonan_reg_auditor'] ??= _fileFromUrl(fileUrl);
      } else if (label.contains('permohonan') && label.contains('latik')) {
        docs['permohonan_reg_latik'] ??= _fileFromUrl(fileUrl);
      } else if (label.contains('ikatan kerja') ||
          label.contains('perjanjian') ||
          label.contains('kontrak') ||
          label.contains('pkwt')) {
        docs['ikatan_kerja_auditor'] ??= _fileFromUrl(fileUrl);
      } else if ((label.contains('non') && label.contains('asn')) ||
          (label.contains('pernyataan') && label.contains('auditor'))) {
        docs['pernyataan_non_asn'] ??= _fileFromUrl(fileUrl);
      }
    }

    return docs;
  }

  _AkreditasiPrefill _mapAkreditasi(Map<String, dynamic> profile) {
    String? nomor = _pickValue(profile, const [
      'nomor_kan',
      'no_kan',
      'nomor_sertifikat_kan',
      'nomor_sertifikat',
    ]);
    DateTime? terbit = _parseDate(_pickValue(profile, const [
      'tanggal_terbit_kan',
      'tgl_terbit_kan',
      'tanggal_terbit',
    ]));
    DateTime? berakhir = _parseDate(_pickValue(profile, const [
      'tanggal_berakhir_kan',
      'tgl_berakhir_kan',
      'tanggal_berakhir',
      'tanggal_berakhir_akreditasi',
      'tgl_berakhir_akreditasi',
      'tanggal_akhir_kan',
      'masa_berlaku_sampai',
      'expired_at',
    ]));
    FileItem? file = _fileFromUrl(_pickValue(profile, const [
      'file_cer_kan',
      'file_kan',
      'sertifikat_kan',
      'file_sertifikat_kan',
    ]));

    final oLatik = profile['o_latik'] is Map
        ? Map<String, dynamic>.from(profile['o_latik'])
        : const <String, dynamic>{};
    final rawLingkup = profile['ruang_lingkup'] ??
        profile['ruang_lingkup_kan'] ??
        profile['ruang_lingkup_akreditasi'] ??
        profile['ruang_lingkup_sertifikasi'] ??
        profile['ruang_lingkup_sertifikat'] ??
        profile['scope'] ??
        profile['scope_akreditasi'] ??
        profile['scope_kan'] ??
        oLatik['ruang_lingkup'] ??
        oLatik['ruang_lingkup_kan'] ??
        oLatik['ruang_lingkup_akreditasi'] ??
        oLatik['ruang_lingkup_sertifikasi'] ??
        oLatik['ruang_lingkup_sertifikat'] ??
        oLatik['scope'] ??
        oLatik['scope_akreditasi'] ??
        oLatik['scope_kan'] ??
        oLatik['lingkup_pendaftaran'];
    final ruangLingkup = <String>[];
    if (rawLingkup is Map) {
      final map = Map<String, dynamic>.from(rawLingkup);
      final labels = <String, String>{
        'aplikasi': 'Audit Aplikasi SPBE',
        'infrastruktur': 'Audit Infrastruktur SPBE',
        'organisasi': 'Audit Organisasi SPBE',
      };
      for (final entry in labels.entries) {
        final v = map[entry.key];
        final enabled = v == true || v == 1 || v == '1';
        if (enabled) ruangLingkup.add(entry.value);
      }
    } else if (rawLingkup is List) {
      for (final item in rawLingkup) {
        final text = item?.toString().trim();
        if (text != null && text.isNotEmpty && text != 'null') {
          ruangLingkup.add(text);
        }
      }
    } else if (rawLingkup is String) {
      ruangLingkup.addAll(
        rawLingkup
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty && e != 'null'),
      );
    }

    final docs = profile['dokumen_kelengkapan'];
    if (docs is List) {
      for (final item in docs.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        final isi = map['isi'] is Map
            ? Map<String, dynamic>.from(map['isi'])
            : const <String, dynamic>{};
        final label = _pickValue(isi, const [
              'nama_dokumen',
              'nama',
              'name',
              'dokumen',
              'jenis_dokumen'
            ])?.toLowerCase() ??
            _pickValue(map, const [
              'nama_dokumen',
              'nama',
              'name',
              'dokumen',
              'jenis_dokumen'
            ])?.toLowerCase() ??
            '';
        final isKan = label.contains('akreditasi') || label.contains('kan');
        if (!isKan) continue;
        nomor ??= _pickValue(
                isi, const ['nomor', 'nomor_dokumen', 'nomor_sertifikat']) ??
            _pickValue(
                map, const ['nomor', 'nomor_dokumen', 'nomor_sertifikat']);
        terbit ??= _parseDate(_pickValue(
                isi, const ['tanggal', 'tanggal_dokumen', 'tgl_dokumen']) ??
            _pickValue(
                map, const ['tanggal', 'tanggal_dokumen', 'tgl_dokumen']));
        file ??= _fileFromUrl(_pickValue(isi, const [
              'url_dokumen',
              'file',
              'path',
              'url',
              'file_url',
              'url_filename'
            ]) ??
            _pickValue(map, const [
              'url_dokumen',
              'file',
              'path',
              'url',
              'file_url',
              'url_filename'
            ]));
        if (nomor != null && file != null && terbit != null) break;
      }
    }

    return _AkreditasiPrefill(
      nomor: nomor,
      terbit: terbit,
      berakhir: berakhir,
      ruangLingkup: ruangLingkup,
      file: file,
    );
  }

  DateTime? _parseDate(String? value) => parseFlexibleDate(value);

  FileItem? _fileFromUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final clean = url.trim();
    final name = clean.split('/').last.split('?').first;
    return FileItem(
        path: clean, name: name.isEmpty ? 'dokumen' : name, size: 0);
  }

  String? _pickValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final raw = data[key];
      if (raw == null) continue;
      final text = raw.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return null;
  }

  String _normalizeProvince(String text) {
    if (text.isEmpty) return text;
    const numericMap = {
      '11': 'Aceh',
      '12': 'Sumatera Utara',
      '13': 'Sumatera Barat',
      '14': 'Riau',
      '15': 'Jambi',
      '16': 'Sumatera Selatan',
      '17': 'Bengkulu',
      '18': 'Lampung',
      '19': 'Kepulauan Bangka Belitung',
      '21': 'Kepulauan Riau',
      '31': 'DKI Jakarta',
      '32': 'Jawa Barat',
      '33': 'Jawa Tengah',
      '34': 'DI Yogyakarta',
      '35': 'Jawa Timur',
      '36': 'Banten',
      '51': 'Bali',
      '52': 'Nusa Tenggara Barat',
      '53': 'Nusa Tenggara Timur',
      '61': 'Kalimantan Barat',
      '62': 'Kalimantan Tengah',
      '63': 'Kalimantan Selatan',
      '64': 'Kalimantan Timur',
      '65': 'Kalimantan Utara',
      '71': 'Sulawesi Utara',
      '72': 'Sulawesi Tengah',
      '73': 'Sulawesi Selatan',
      '74': 'Sulawesi Tenggara',
      '75': 'Gorontalo',
      '76': 'Sulawesi Barat',
      '81': 'Maluku',
      '82': 'Maluku Utara',
      '91': 'Papua',
      '92': 'Papua Barat',
    };
    final numeric = numericMap[text];
    if (numeric != null) return numeric;
    const map = {
      'DKI JAKARTA': 'DKI Jakarta',
      'DI YOGYAKARTA': 'DI Yogyakarta',
      'JAWA TIMUR': 'Jawa Timur',
      'JAWA BARAT': 'Jawa Barat',
      'JAWA TENGAH': 'Jawa Tengah',
      'BANTEN': 'Banten',
    };
    return map[text.toUpperCase()] ?? text;
  }
}

class _AkreditasiPrefill {
  final String? nomor;
  final DateTime? terbit;
  final DateTime? berakhir;
  final List<String> ruangLingkup;
  final FileItem? file;

  const _AkreditasiPrefill({
    this.nomor,
    this.terbit,
    this.berakhir,
    this.ruangLingkup = const [],
    this.file,
  });
}

final registrasiServiceProvider =
    Provider((ref) => RegistrasiService(ref.watch(dioProvider)));
final registrasiRepoProvider = Provider(
    (ref) => RegistrasiRepository(ref.watch(registrasiServiceProvider)));
final latikServiceProvider =
    Provider((ref) => LatikService(ref.watch(dioProvider)));
final registrasiProvider =
    StateNotifierProvider<RegistrasiNotifier, RegistrasiState>(
        (ref) => RegistrasiNotifier(
              ref.watch(registrasiRepoProvider),
              ref.watch(profileMenuServiceProvider),
              ref.watch(latikServiceProvider),
              ref.watch(auditorRepoProvider),
            ));

final registrasiBootstrapProvider =
    FutureProvider.autoDispose<void>((ref) async {
  final user = ref.watch(authProvider).user;
  final latikRef = user?['latik_ref']?.toString();
  await ref
      .read(registrasiProvider.notifier)
      .initializeFromApi(latikRef: latikRef);
  ref
      .read(auditorProvider.notifier)
      .setAll(ref.read(registrasiProvider).data.auditors);
});
