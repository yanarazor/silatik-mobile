import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/url_opener.dart';
import '../../data/models/latik_profile.dart';
import '../../providers/auditor_provider.dart';
import '../../providers/profile_menu_provider.dart';
import '../shared/latik_info_section.dart';

const _green = Color(0xFF25B45B);
const _amber = Color(0xFFE8A000);
const _cardBorder = Color(0xFFE5EAF3);
const _blueTint = Color(0xFFEAF2FB);
const _blueTintBorder = Color(0xFFD5E5F7);

class ProfilLembagaScreen extends ConsumerWidget {
  const ProfilLembagaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(latikProfileProvider);
    final auditorCount =
        ref.watch(auditorListProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Profil Lembaga'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Gagal memuat data profil.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(latikProfileProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (data) {
          if (data.isEmpty) {
            return _EmptyProfileState(
              onRetry: () => ref.invalidate(latikProfileProvider),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              _IdentityCard(data: data),
              const SizedBox(height: 12),
              _StatsRow(data: data, auditorCount: auditorCount),
              const SizedBox(height: 16),
              LatikInfoSection(data: data),
              if (LatikLocationCard.maybeBuild(data) case final map?) ...[
                const SizedBox(height: 16),
                map,
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: profileAsync.maybeWhen(
        data: (data) => _EditFooter(
          onEdit: () =>
              context.push(AppRoutes.profilLembagaEdit, extra: data),
        ),
        orElse: () => null,
      ),
    );
  }
}

class _EmptyProfileState extends StatelessWidget {
  const _EmptyProfileState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
        children: [
          Icon(
            Icons.apartment_outlined,
            size: 56,
            color: AppColors.primary.withValues(alpha: 0.65),
          ),
          const SizedBox(height: 16),
          const Text(
            'Profil lembaga belum tersedia',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Data profil belum dikirim oleh server. Tarik layar untuk memuat ulang.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}

class _EditFooter extends StatelessWidget {
  const _EditFooter({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4ECF7))),
        boxShadow: [
          BoxShadow(
            color: Color(0x140C2D5C),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 20),
            label: const Text('Edit Profil Lembaga'),
          ),
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.data});

  final LatikProfile data;

  @override
  Widget build(BuildContext context) {
    final str = _strInfo(data);
    final badges = _statusBadges(data);

    final displayName =
        data.namaLatik.isEmpty ? 'Nama Lembaga Belum Diisi' : data.namaLatik;
    final displayReg =
        data.noPendaftaran.isEmpty ? 'Belum Terdaftar' : data.noPendaftaran;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _blueTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _blueTintBorder),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.tag,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            displayReg,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final b in badges.isEmpty
                            ? [const _PillSpec('Belum Terverifikasi', _amber)]
                            : badges)
                          _Pill(spec: b),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (str != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: Color(0xFFF0F2F7)),
            ),
            _StrCard(info: str),
          ],
        ],
      ),
    );
  }
}

class _StrCard extends StatelessWidget {
  const _StrCard({required this.info});

  final _StrInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAF2FB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Surat Tanda Registrasi (STR)',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              _Pill(spec: info.statusSpec),
            ],
          ),
          const SizedBox(height: 4),
          _PairRow(
            label: 'No. STR',
            value: info.no,
            mono: true,
          ),
          if (info.period.isNotEmpty)
            _PairRow(
              label: 'Masa Berlaku',
              value: info.period,
            ),
          if (info.fileUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFEAF2FB)),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => openFileUrl(context, info.fileUrl),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Buka',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.open_in_new_rounded,
                      size: 15, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.data, required this.auditorCount});

  final LatikProfile data;
  final int auditorCount;

  @override
  Widget build(BuildContext context) {
    final count = data.auditorCount > 0 ? data.auditorCount : auditorCount;
    final statusValue =
        data.statusText.isEmpty ? 'Belum Terverifikasi' : data.statusText;
    final verified = data.isVerified;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _StatCard(
              iconBg: _blueTint,
              iconColor: AppColors.primary,
              icon: Icons.group_rounded,
              label: 'Total Auditor',
              value: '$count Orang',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: _StatCard(
              iconBg: verified
                  ? _green.withValues(alpha: 0.12)
                  : _amber.withValues(alpha: 0.12),
              iconColor: verified ? _green : _amber,
              icon: verified ? Icons.verified_rounded : Icons.pending_rounded,
              label: 'Status Verifikasi',
              value: statusValue,
              valueColor: verified ? _green : _amber,
              valueMaxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C2D5C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueMaxLines = 1,
  });

  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final int valueMaxLines;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: valueMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor ?? AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PairRow extends StatelessWidget {
  const _PairRow({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: mono ? 'monospace' : null,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.spec});

  final _PillSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: spec.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: spec.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: spec.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            spec.label,
            style: TextStyle(
              color: spec.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillSpec {
  const _PillSpec(this.label, this.color);

  final String label;
  final Color color;
}

class _StrInfo {
  const _StrInfo({
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
  final _PillSpec statusSpec;
  final String fileUrl;
}

// ponytail: status/semantics diturunkan dari teks+kode (lihat enums.dart);
// kalau backend mengirim status yang belum dikenal, label kembali ke teks aslinya.
_StrInfo? _strInfo(LatikProfile data) {
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

  final _PillSpec statusSpec;
  if (expired) {
    statusSpec = const _PillSpec('Kadaluarsa', AppColors.error);
  } else if (isActive) {
    statusSpec = const _PillSpec('Aktif', _green);
  } else {
    statusSpec = const _PillSpec('Nonaktif', _amber);
  }

  final period = _periodText(start, end);
  return _StrInfo(
    no: no.isEmpty ? '-' : no,
    start: start,
    end: end,
    period: period,
    statusSpec: statusSpec,
    fileUrl: data.fileStr.trim(),
  );
}

// ponytail: status/semantik diturunkan dari teks+kode (mirror enums.dart);
// status baru yang tak dikenal jatuh ke label teks apa adanya.
List<_PillSpec> _statusBadges(LatikProfile data) {
  final rawStatus = data.statusText.trim().toLowerCase();
  if (rawStatus.isNotEmpty &&
      (rawStatus == '4' ||
          rawStatus.contains('aktif') ||
          rawStatus.contains('terverifikasi') ||
          rawStatus.contains('approved') ||
          rawStatus.contains('valid'))) {
    return const [
      _PillSpec('Terverifikasi', _green),
      _PillSpec('Valid', _green),
    ];
  }
  final label = _statusLabel(rawStatus);
  if (label == null) {
    return const [_PillSpec('Belum Terverifikasi', _amber)];
  }
  final rejected = rawStatus.contains('dikembalikan') ||
      rawStatus.contains('ditolak') ||
      rawStatus.contains('dicabut') ||
      rawStatus.contains('kadaluarsa') ||
      rawStatus.contains('expired') ||
      rawStatus == '2';
  return [_PillSpec(label, rejected ? AppColors.error : _amber)];
}

String? _statusLabel(String rawStatus) {
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

String _periodText(DateTime? start, DateTime? end) {
  if (start != null && end != null) {
    return '${AppFormatters.formatShortDate(start)} – '
        '${AppFormatters.formatShortDate(end)}';
  }
  if (end != null) return 's.d. ${AppFormatters.formatShortDate(end)}';
  if (start != null) return 'sejak ${AppFormatters.formatShortDate(start)}';
  return '';
}


