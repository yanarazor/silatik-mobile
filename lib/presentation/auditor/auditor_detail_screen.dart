import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/auditor_model.dart';

class AuditorDetailScreen extends StatelessWidget {
  final AuditorModel auditor;
  const AuditorDetailScreen({super.key, required this.auditor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Auditor',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                    child: _buildAvatar(theme, auditor),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auditor.nama,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'NIK: ${AppFormatters.maskNik(auditor.nik)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildSectionTitle('Profil Auditor'),
          _buildInfo(context, 'Nama Auditor', auditor.nama, Icons.person),
          const SizedBox(height: AppTheme.spacing12),
          _buildInfo(context, 'NIK Auditor', auditor.nik, Icons.badge_outlined),
          const SizedBox(height: AppTheme.spacing12),
          _buildInfo(
              context, 'Email Auditor', auditor.email, Icons.email_outlined),
          const SizedBox(height: AppTheme.spacing12),
          _buildInfo(context, 'Nomor Telepon Auditor', auditor.phone,
              Icons.phone_android),
          const SizedBox(height: AppTheme.spacing12),
          _buildInfo(context, 'Tempat Lahir Auditor', auditor.tempatLahir,
              Icons.location_on_outlined),
          const SizedBox(height: AppTheme.spacing12),
          _buildInfo(
            context,
            'Tanggal Lahir Auditor',
            AppFormatters.formatDate(auditor.tanggalLahir),
            Icons.event,
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildInfo(context, 'Provinsi Auditor', auditor.provinsi,
              Icons.map_outlined),
          const SizedBox(height: AppTheme.spacing12),
          _buildInfo(context, 'Kota/Kabupaten Auditor', auditor.kabupaten,
              Icons.location_city_outlined),
          const SizedBox(height: AppTheme.spacing12),
          _buildInfo(context, 'Kode Pos Auditor', auditor.kodePos,
              Icons.local_post_office_outlined),
          const SizedBox(height: AppTheme.spacing12),
          _buildInfo(
              context, 'Agama Auditor', auditor.agama, Icons.self_improvement),
          const SizedBox(height: AppTheme.spacing12),
          _buildInfo(context, 'Auditor Aktif', auditor.activeLabel,
              Icons.verified_user_outlined),
          const SizedBox(height: AppTheme.spacing12),
          _buildInfo(context, 'Status Auditor', auditor.statusLabel,
              Icons.assignment_turned_in_outlined),
          const SizedBox(height: AppTheme.spacing12),
          _buildInfo(
              context, 'Keterangan', auditor.keterangan, Icons.notes_outlined),
          const SizedBox(height: AppTheme.spacing20),
          _buildSectionTitle('Sertifikasi Teknis'),
          _buildInfo(context, 'Nomor Sertifikasi', auditor.nomorSertifikasi,
              Icons.card_membership),
          const SizedBox(height: AppTheme.spacing12),
          _buildInfo(context, 'Lembaga Penerbit', auditor.lembagaPenerbit,
              Icons.business),
          const SizedBox(height: AppTheme.spacing12),
          _buildInfo(context, 'Kompetensi', auditor.kompetensi.join(', '),
              Icons.verified),
          if (auditor.certificates.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing12),
            ...auditor.certificates.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
                  child: _buildCertificateCard(context, item),
                )),
          ],
          const SizedBox(height: AppTheme.spacing20),
          _buildSectionTitle('Data Dukung'),
          _buildDocCard(context, 'KTP', auditor.ktpFileUrl),
          _buildDocCard(context, 'Sertifikat Kompetensi',
              auditor.sertifikatKompetensiUrl),
          _buildDocCard(context, 'Portofolio Auditor', auditor.portofolioUrl),
          _buildDocCard(
              context, 'Dokumen Praktik SPBE', auditor.praktikAuditUrl),
          _buildDocCard(context, 'Bukti Keanggotaan Asosiasi Profesi',
              auditor.asosiasiProfesiUrl),
          _buildDocCard(context, 'Pernyataan Integritas',
              auditor.pernyataanIntegritasUrl),
          _buildDocCard(
              context, 'Surat Permohonan', auditor.suratPermohonanUrl),
          _buildDocCard(context, 'Pengangkatan', auditor.pengangkatanUrl),
          const SizedBox(height: AppTheme.spacing20),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit),
            label: const Text('Edit Auditor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.block, color: AppColors.error),
            label: const Text('Nonaktifkan Auditor'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(
      BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          value.isEmpty ? '-' : value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing8,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF0C2D5C),
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildDocCard(BuildContext context, String label, String url) {
    final hasUrl = url.trim().isNotEmpty;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ListTile(
        leading:
            const Icon(Icons.description_outlined, color: AppColors.primary),
        title: Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        subtitle: Text(
          hasUrl ? 'Tersedia' : '-',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: hasUrl
            ? TextButton(
                onPressed: () => _openUrl(context, url),
                child: const Text('Lihat File'),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing8,
        ),
      ),
    );
  }

  Widget _buildCertificateCard(BuildContext context, AuditorCertificate cert) {
    final hasUrl = cert.fileUrl.trim().isNotEmpty;
    return Card(
      elevation: 0,
      color: const Color(0xFFF7FAFE),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ListTile(
        leading: const Icon(Icons.workspace_premium_outlined,
            color: AppColors.primary),
        title: Text(
          cert.nama.isEmpty ? 'Sertifikasi Teknis' : cert.nama,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        subtitle: Text(
          [cert.lembaga, cert.tahun].where((e) => e.isNotEmpty).join(' • '),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        trailing: hasUrl
            ? TextButton(
                onPressed: () => _openUrl(context, cert.fileUrl),
                child: const Text('Lihat'),
              )
            : null,
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, AuditorModel auditor) {
    final url = auditor.fotoUrl.trim();
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialsAvatar(theme, auditor),
        ),
      );
    }
    return _buildInitialsAvatar(theme, auditor);
  }

  Widget _buildInitialsAvatar(ThemeData theme, AuditorModel auditor) {
    return Center(
      child: Text(
        auditor.nama.isNotEmpty ? auditor.nama[0].toUpperCase() : 'A',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnackBar(context, 'URL tidak valid');
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
