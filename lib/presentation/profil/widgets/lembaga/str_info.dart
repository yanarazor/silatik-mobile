import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/latik_profile.dart';
import 'lembaga_cards.dart';
import 'lembaga_colors.dart';

/// Derived STR display info for the institution identity card.
class StrInfo {
  const StrInfo({
    required this.no,
    required this.start,
    required this.end,
    required this.period,
    required this.statusSpec,
    required this.fileUrl,
  });

  final String no;
  final DateTime? start;
  final DateTime? end;
  final String period;
  final PillSpec statusSpec;
  final String fileUrl;
}

// ponytail: status/semantics diturunkan dari teks+kode (lihat enums.dart);
// kalau backend mengirim status yang belum dikenal, label kembali ke teks aslinya.
StrInfo? strInfo(LatikProfile data) {
  final no = data.noStr;
  final start = data.strTanggalAwal;
  final end = data.strTanggalAkhir;
  if (no.isEmpty && start == null && end == null) return null;

  final expired = end != null && !end.isAfter(DateTime.now());
  final rawStatus =
      (data.strStatus.isNotEmpty ? data.strStatus : data.namaStatusStr)
          .toLowerCase();
  final isNonaktif = expired ||
      rawStatus.contains('nonaktif') ||
      rawStatus.contains('kadaluarsa') ||
      rawStatus.contains('expired') ||
      rawStatus.contains('dicabut') ||
      rawStatus == '0';
  final isActive = !isNonaktif &&
      (rawStatus.isEmpty ||
          rawStatus == '1' ||
          rawStatus == '4' ||
          rawStatus.contains('aktif') ||
          rawStatus.contains('valid') ||
          rawStatus.contains('publish'));

  final PillSpec statusSpec;
  if (expired) {
    statusSpec = const PillSpec('Kadaluarsa', AppColors.error);
  } else if (isActive) {
    statusSpec = const PillSpec('Aktif', lembagaGreen);
  } else {
    statusSpec = const PillSpec('Nonaktif', lembagaAmber);
  }

  return StrInfo(
    no: no.isEmpty ? '-' : no,
    start: start,
    end: end,
    period: periodText(start, end),
    statusSpec: statusSpec,
    fileUrl: data.fileStr.trim(),
  );
}

// ponytail: status/semantik diturunkan dari teks+kode (mirror enums.dart);
// status baru yang tak dikenal jatuh ke label teks apa adanya.
// The badge reflects the institution's verification status (data.statusText),
// NOT the STR validity. An STR can still be within its date range while the
// latest verification was returned/rejected ("Dikembalikan"), so an active STR
// must not short-circuit this to "Terverifikasi". STR active/expired state has
// its own badge in the STR card.
List<PillSpec> statusBadges(LatikProfile data) {
  final rawStatus = data.statusText.trim().toLowerCase();
  if (rawStatus.isNotEmpty &&
      (rawStatus == '4' ||
          rawStatus.contains('aktif') ||
          rawStatus.contains('terverifikasi') ||
          rawStatus.contains('approved') ||
          rawStatus.contains('valid'))) {
    return const [
      PillSpec('Terverifikasi', lembagaGreen),
      PillSpec('Valid', lembagaGreen),
    ];
  }
  final label = statusLabel(rawStatus);
  if (label == null) {
    return const [PillSpec('Belum Terverifikasi', lembagaAmber)];
  }
  final rejected = rawStatus.contains('dikembalikan') ||
      rawStatus.contains('ditolak') ||
      rawStatus.contains('dicabut') ||
      rawStatus.contains('kadaluarsa') ||
      rawStatus.contains('expired') ||
      rawStatus == '2';
  return [PillSpec(label, rejected ? AppColors.error : lembagaAmber)];
}

String? statusLabel(String rawStatus) {
  if (rawStatus.isEmpty) return null;
  const codeMap = {
    '0': 'Registrasi',
    '1': 'Proses Verifikasi',
    '2': 'Dikembalikan',
    '3': 'Penerbitan STR',
    '4': 'Aktif',
    '5': 'Kadaluarsa',
    '6': 'Dibekukan',
    '7': 'Dicabut',
    '8': 'Menunggu Pembayaran',
  };
  final byCode = codeMap[rawStatus];
  if (byCode != null) return byCode;
  const textMap = {
    'registrasi': 'Registrasi',
    'proses verifikasi': 'Proses Verifikasi',
    'dikembalikan': 'Dikembalikan',
    'proses penerbitan str': 'Penerbitan STR',
    'aktif': 'Aktif',
    'kadaluarsa': 'Kadaluarsa',
    'dibekukan': 'Dibekukan',
    'dicabut': 'Dicabut',
    'menunggu pembayaran': 'Menunggu Pembayaran',
    'terverifikasi': 'Terverifikasi',
  };
  final byText = textMap[rawStatus.replaceAll('_', ' ').trim()];
  if (byText != null) return byText;
  return null;
}

String periodText(DateTime? start, DateTime? end) {
  if (start != null && end != null) {
    return '${AppFormatters.formatShortDate(start)} – '
        '${AppFormatters.formatShortDate(end)}';
  }
  if (end != null) return 's.d. ${AppFormatters.formatShortDate(end)}';
  if (start != null) return 'sejak ${AppFormatters.formatShortDate(start)}';
  return '';
}