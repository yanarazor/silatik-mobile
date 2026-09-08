import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/auditor_model.dart';
import '../../data/models/master_data_model.dart';
import '../../providers/auditor_provider.dart';
import '../../providers/master_data_provider.dart';

class AuditorDetailScreen extends ConsumerStatefulWidget {
  final AuditorModel auditor;
  const AuditorDetailScreen({super.key, required this.auditor});

  @override
  ConsumerState<AuditorDetailScreen> createState() =>
      _AuditorDetailScreenState();
}

class _AuditorDetailScreenState extends ConsumerState<AuditorDetailScreen> {
  bool _showNik = false;

  // ponytail: /latik/auditor/view tidak mengembalikan auditor_ext, jadi render
  // langsung dari item daftar (/latik/auditors) yang justru paling lengkap.
  AuditorModel get _auditor => widget.auditor;

  AsyncValue<List<AuditorDocument>>? get _docsAsync =>
      ref.watch(auditorDocsProvider(widget.auditor.id));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Auditor',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.spacing16, AppTheme.spacing16, AppTheme.spacing16, 32),
        children: [
          _buildHeaderCard(context),
          const SizedBox(height: AppTheme.spacing16),
          _SectionCard(
            title: 'Profil Auditor',
            child: _buildProfileRows(context),
          ),
          const SizedBox(height: AppTheme.spacing12),
          _SectionCard(
            title: 'Sertifikat Pelatihan',
            countLabel: _auditor.certificates.isEmpty
                ? null
                : '${_auditor.certificates.length} Pelatihan',
            child: _buildCertificates(context),
          ),
          const SizedBox(height: AppTheme.spacing12),
          _SectionCard(
            title: 'Dokumen',
            countLabel: _buildDocsCount(),
            child: _buildDocuments(context),
          ),
          const SizedBox(height: AppTheme.spacing12),
          _SectionCard(
            title: 'Perpanjangan',
            countLabel: _auditor.auditorExt.isEmpty
                ? null
                : '${_auditor.auditorExt.length} Riwayat',
            child: _buildExtensions(context),
          ),
          const SizedBox(height: AppTheme.spacing24),
          _buildActions(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Header

  Widget _buildHeaderCard(BuildContext context) {
    return _card(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(context),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _auditor.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _buildNikRow(),
                    const SizedBox(height: 6),
                    _buildHeaderChips(),
                  ],
                ),
              ),
            ],
          ),
          if (_hasStr) ...[
            const SizedBox(height: AppTheme.spacing16),
            const _SectionDivider(),
            const SizedBox(height: AppTheme.spacing16),
            _buildStrCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final url = _auditor.fotoUrl.trim();
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildInitialsAvatar(),
            )
          : _buildInitialsAvatar(),
    );
  }

  Widget _buildInitialsAvatar() {
    final initials = _auditor.nama
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();
    return Center(
      child: Text(
        initials.isEmpty ? 'A' : initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildNikRow() {
    final nik = _auditor.nik;
    final nikText = _showNik ? nik : _maskNik(nik);
    return Row(
      children: [
        Flexible(
          child: Text(
            nik.isEmpty ? 'NIK belum diisi' : 'NIK: $nikText',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (nik.isNotEmpty) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => setState(() => _showNik = !_showNik),
            tooltip: _showNik ? 'Sembunyikan NIK' : 'Tampilkan NIK',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            icon: Icon(
              _showNik ? Icons.visibility_off : Icons.visibility,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  String _maskNik(String nik) {
    final middle = nik.length - 8;
    if (middle <= 0) return '••••';
    return '${nik.substring(0, 4)}${'•' * middle}'
        '${nik.substring(nik.length - 4)}';
  }

  Widget _buildHeaderChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (_auditor.statusAktif == 1)
          _chip(
            'Aktif',
            bg: AppColors.success.withValues(alpha: 0.10),
            fg: AppColors.success,
            dot: true,
          )
        else
          _chip(
            'Tidak Aktif',
            bg: AppColors.textSecondary.withValues(alpha: 0.10),
            fg: AppColors.textSecondary,
          ),
        if (_auditor.statusVerifikasi == 1)
          _chip(
            'Terverifikasi',
            bg: AppColors.primaryLight.withValues(alpha: 0.12),
            fg: AppColors.primaryLight,
            icon: Icons.verified,
          )
        else
          _chip(
            'Belum Verifikasi',
            bg: AppColors.textSecondary.withValues(alpha: 0.10),
            fg: AppColors.textSecondary,
            icon: Icons.gpp_bad,
          ),
      ],
    );
  }

  bool get _hasStr =>
      _auditor.strNo.isNotEmpty ||
      _auditor.strTanggalAwal != null ||
      _auditor.strTanggalAkhir != null;

  bool get _strExpired =>
      _auditor.strTanggalAkhir != null &&
      _auditor.strTanggalAkhir!.isBefore(DateTime.now());

  bool get _strValid => _auditor.strStatus == 1 && !_strExpired;

  Widget _buildStrCard() {
    final String strLabel;
    final Color strColor;
    if (_strValid) {
      strLabel = 'Berlaku / Sah';
      strColor = AppColors.success;
    } else if (_strExpired) {
      strLabel = 'Kedaluwarsa';
      strColor = AppColors.error;
    } else {
      strLabel = 'Belum Disahkan';
      strColor = AppColors.warning;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user,
                  size: 18, color: AppColors.primaryLight),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Surat Tanda Registrasi (STR)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _chip(
                strLabel,
                bg: strColor.withValues(alpha: 0.12),
                fg: strColor,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              Expanded(
                child: _strField(
                    'Nomor STR', _auditor.strNo, AppColors.textPrimary),
              ),
              Expanded(
                child: _strField(
                  'Masa Berlaku',
                  _period(_auditor.strTanggalAwal, _auditor.strTanggalAkhir),
                  _strExpired ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _strField(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '-' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------- Profil Auditor

  Widget _buildProfileRows(BuildContext context) {
    final (provinsi, kabupaten) = _resolveRegion();
    final rows = <(String, String, bool)>[
      ('Email', _auditor.email, false),
      ('No. Handphone', _auditor.phone, false),
      (
        'Tempat, Tanggal Lahir',
        [_auditor.tempatLahir, AppFormatters.formatDate(_auditor.tanggalLahir)]
            .where((e) => e.isNotEmpty && e != '-')
            .join(', '),
        false
      ),
      ('Alamat Domisili', _auditor.alamat, false),
      (
        'Kab/Kota & Provinsi',
        [kabupaten, provinsi].where((e) => e.isNotEmpty).join(', '),
        false
      ),
      ('Kode Pos', _auditor.kodePos, false),
      ('Agama', _auditor.agama, false),
      ('Status Auditor', _auditor.statusLabel, true),
      // ('Status Keaktifan', _auditor.activeLabel, false),
      ('Keterangan', _auditor.keterangan, false),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          _profileRow(rows[i].$1, rows[i].$2, emphasized: rows[i].$3),
          if (i != rows.length - 1) const _SectionDivider(),
        ],
      ],
    );
  }

  Widget _profileRow(String label, String value, {bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value.isEmpty ? '-' : value,
            style: TextStyle(
              color:
                  emphasized ? AppColors.primaryLight : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------- Sertifikat Pelatihan

  /// Provinsi/kabupaten disimpan sebagai kode di API auditor; resolusi ke nama
  /// dari master /provinsi & /kabupaten. Nilai non-numerik dianggap sudah nama.
  (String, String) _resolveRegion() {
    final rawProv = _auditor.provinsi.trim();
    final rawKab = _auditor.kabupaten.trim();
    final provinsiAll =
        ref.watch(provinsiListProvider).valueOrNull ?? const <ProvinsiModel>[];
    var kabProvId = _isNumericId(rawProv) ? rawProv : null;
    var provinsi = rawProv;
    if (kabProvId != null) {
      for (final p in provinsiAll) {
        if (p.id == rawProv) {
          provinsi = p.nama;
          break;
        }
      }
    } else if (provinsiAll.isNotEmpty) {
      for (final p in provinsiAll) {
        if (p.nama == rawProv) {
          provinsi = p.nama;
          kabProvId = p.id;
          break;
        }
      }
    }
    var kabupaten = rawKab;
    if (kabProvId != null && _isNumericId(rawKab)) {
      final kabs = ref.watch(kabupatenListProvider(kabProvId)).valueOrNull ??
          const <KabupatenModel>[];
      for (final k in kabs) {
        if (k.id == rawKab) {
          kabupaten = k.nama;
          break;
        }
      }
    }
    return (provinsi, kabupaten);
  }

  bool _isNumericId(String value) =>
      value.isNotEmpty && RegExp(r'^\d+$').hasMatch(value);
  Widget _buildCertificates(BuildContext context) {
    if (_auditor.certificates.isEmpty) {
      return const _EmptySection('Belum ada sertifikat pelatihan');
    }
    return Column(
      children: [
        for (final cert in _auditor.certificates)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
            child: _buildCertificateRow(context, cert),
          ),
      ],
    );
  }

  Widget _buildCertificateRow(BuildContext context, AuditorCertificate cert) {
    final hasUrl = cert.fileUrl.trim().isNotEmpty;
    final subtitle = [
      if (cert.lembaga.isNotEmpty) cert.lembaga,
      if (cert.tahun.isNotEmpty) 'Tahun ${cert.tahun}',
    ].join(' • ');
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall + 1),
            ),
            child: const Icon(Icons.military_tech,
                size: 20, color: AppColors.primaryLight),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.nama.isEmpty ? 'Sertifikat Pelatihan' : cert.nama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasUrl) ...[
            const SizedBox(width: AppTheme.spacing8),
            InkWell(
              onTap: () => _openUrl(context, cert.fileUrl),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall + 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.open_in_new,
                        size: 14, color: AppColors.primaryLight),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------ Dokumen

  String? _buildDocsCount() {
    final docs = _docsAsync?.valueOrNull;
    if (docs == null) return null;
    return docs.isEmpty ? null : '${docs.length} Berkas';
  }

  Widget _buildDocuments(BuildContext context) {
    final docsAsync = _docsAsync!;
    if (docsAsync.isLoading && !docsAsync.hasValue) {
      return const Padding(
        padding: EdgeInsets.all(AppTheme.spacing16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (docsAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
        child: Column(
          children: [
            const Text(
              'Gagal memuat dokumen',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.invalidate(auditorDocsProvider(widget.auditor.id)),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    final docs = docsAsync.valueOrNull ?? [];
    if (docs.isEmpty) {
      return const _EmptySection('Belum ada berkas dokumen');
    }
    return Column(
      children: [
        for (var i = 0; i < docs.length; i++) ...[
          _buildDocumentRow(context, docs[i]),
          if (i != docs.length - 1) const _SectionDivider(),
        ],
      ],
    );
  }

  Widget _buildDocumentRow(BuildContext context, AuditorDocument doc) {
    final label = doc.nama.isEmpty
        ? (doc.field.isEmpty ? 'Dokumen' : doc.field)
        : doc.nama;
    final verified = doc.statusVerifikasi == 1;
    return InkWell(
      onTap: doc.url.isEmpty ? null : () => _openUrl(context, doc.url),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spacing8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(_docIcon(label),
                  size: 20, color: AppColors.primaryLight),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _buildDocStatus(doc, verified),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            const Icon(Icons.chevron_right,
                size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDocStatus(AuditorDocument doc, bool verified) {
    final Widget status;
    if (verified) {
      status = _chip(
        'Terverifikasi',
        bg: AppColors.success.withValues(alpha: 0.10),
        fg: AppColors.success,
        icon: Icons.check_circle,
      );
    } else {
      status = Text(
        doc.statusVerifikasi == 2 ? 'Tidak Sah' : 'Belum Terverifikasi',
        style: TextStyle(
          color: doc.statusVerifikasi == 2
              ? AppColors.error
              : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    // Keterangan (catatan_verifikasi) hanya tampil bila diisi API.
    final note = doc.catatanVerifikasi.trim();
    if (note.isEmpty) return status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        status,
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline,
                size: 13, color: AppColors.primaryLight),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Keterangan: $note',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _docIcon(String label) {
    final t = label.toLowerCase();
    if (t.contains('ktp')) return Icons.badge_outlined;
    if (t.contains('kompetensi') || t.contains('sertifikat')) {
      return Icons.workspace_premium_outlined;
    }
    if (t.contains('praktik') || t.contains('spbe')) return Icons.task_outlined;
    if (t.contains('asosiasi') || t.contains('anggota')) {
      return Icons.card_membership_outlined;
    }
    if (t.contains('integritas') || t.contains('pakta')) {
      return Icons.history_edu_outlined;
    }
    if (t.contains('permohonan') ||
        t.contains('pengangkatan') ||
        t.contains('sk ')) {
      return Icons.assignment_turned_in_outlined;
    }
    return Icons.description_outlined;
  }

  // ---------------------------------------------------------------- Aksi

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton.icon(
            // ponytail: alur edit auditor terpisah; biarkan no-op sampai ada
            // full-screen editor auditor.
            onPressed: () {},
            icon: const Icon(Icons.edit_square, size: 20),
            label: const Text(
              'Edit Auditor',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        SizedBox(
          height: 50,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmNonaktifkan(),
            icon: const Icon(Icons.person_off, size: 20),
            label: const Text(
              'Nonaktifkan Auditor',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmNonaktifkan() {
    // ponytail: nonaktifkan = auditor/update (status_aktif=0); alurnya belum
    // dibangun, kasih umpan balik eksplisit dulu, upgrade saat kelola auditor
    // hadir.
    _showSnackBar(context, 'Alur nonaktifkan auditor belum tersedia');
  }

  // -------------------------------------------------------- Perpanjangan

  Widget _buildExtensions(BuildContext context) {
    final ext = _auditor.auditorExt;
    if (ext.isEmpty) {
      return const _EmptySection('Belum ada riwayat perpanjangan');
    }
    return Column(
      children: [
        for (var i = 0; i < ext.length; i++) ...[
          _buildExtensionCard(context, ext[i]),
          if (i != ext.length - 1) const SizedBox(height: AppTheme.spacing8),
        ],
      ],
    );
  }

  Widget _buildExtensionCard(BuildContext context, AuditorExtension ext) {
    final (chipLabel, chipColor) = _extStatus(ext);
    final period = _extPeriod(ext);
    final invoice = ext.invoice;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  period,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _chip(
                chipLabel,
                bg: chipColor.withValues(alpha: 0.12),
                fg: chipColor,
              ),
            ],
          ),
          if (ext.catatanVerifikasi.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              ext.catatanVerifikasi.trim(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacing8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: invoice == null
                    ? const Text(
                        'Belum ada tagihan',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      )
                    : Row(
                        children: [
                          const Text(
                            'Kode: ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              invoice.kodeTagihan,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              Text(
                invoice == null
                    ? '-'
                    : AppFormatters.formatRupiah(invoice.tagihanTotal),
                style: TextStyle(
                  color: invoice == null
                      ? AppColors.textSecondary
                      : AppColors.primaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (String, Color) _extStatus(AuditorExtension ext) {
    if (ext.status == 3) {
      return (
        ext.invoice?.status == 2 ? 'Selesai / Lunas' : 'Selesai',
        AppColors.success
      );
    }
    if (ext.status == 1) return ('Dalam Proses', AppColors.warning);
    return ('Draft', AppColors.textSecondary);
  }

  String _extPeriod(AuditorExtension ext) {
    final start = AppFormatters.formatShortDate(ext.strTanggalAwal);
    final end = AppFormatters.formatShortDate(ext.strTanggalAkhir);
    if (ext.strTanggalAkhir == null) {
      return '${ext.strTanggalAwal == null ? '—' : start} - Sedang Berjalan';
    }
    return '$start - $end';
  }

  // -------------------------------------------------------------- Umum

  String _period(DateTime? start, DateTime? end) {
    final parts = [
      if (start != null) AppFormatters.formatShortDate(start),
      if (end != null) AppFormatters.formatShortDate(end),
    ];
    return parts.isEmpty ? '-' : parts.join(' - ');
  }

  Widget _chip(String label,
      {required Color bg,
      required Color fg,
      IconData? icon,
      bool dot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnackBar(context, 'URL tidak valid');
      return;
    }
    if (url.toLowerCase().endsWith('.pdf')) {
      context.push('${AppRoutes.pdfViewer}?url=${Uri.encodeComponent(url)}');
      return;
    }
    try {
      final externalOk =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (externalOk) return;
      final inAppOk = await launchUrl(uri, mode: LaunchMode.inAppWebView);
      if (!inAppOk) {
        if (!context.mounted) return;
        _showSnackBar(context, 'Tidak bisa membuka tautan');
      }
    } catch (_) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Gagal membuka tautan');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SectionCard extends StatefulWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.countLabel,
  });

  final String title;
  final Widget child;
  final String? countLabel;

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXLarge)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (widget.countLabel != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.countLabel!,
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.spacing16, 0,
                  AppTheme.spacing16, AppTheme.spacing12),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.primary.withValues(alpha: 0.08),
    );
  }
}
