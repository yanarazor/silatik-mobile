import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/url_opener.dart';
import '../../../data/models/auditor_certificate.dart';
import '../../../data/models/auditor_model.dart';
import '../../../providers/auditor_provider.dart';
import '../form/auditor_sertifikasi_screen.dart';
import 'detail_section.dart';

/// Training certificates list, sourced from the server so it stays in sync
/// with the editor. Includes the "Kelola Sertifikasi Teknis" action.
class AuditorDetailCertificates extends ConsumerWidget {
  const AuditorDetailCertificates({super.key, required this.auditor});

  final AuditorModel auditor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sumber kebenaran daftar sertifikat = server (bukan payload auditor), agar
    // konsisten dengan editor & mendapat sertifikat baru/terhapus.
    final certsAsync = ref.watch(auditorSertifikasiProvider(auditor.id));
    final certs = certsAsync.valueOrNull ?? auditor.certificates;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (certsAsync.isLoading && certsAsync.valueOrNull == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.spacing8),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (certs.isEmpty)
          const DetailEmptySection('Belum ada sertifikat pelatihan')
        else
          for (final cert in certs)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
              child: _buildCertificateRow(context, cert),
            ),
        if (auditor.canEdit) ...[
          const SizedBox(height: AppTheme.spacing8),
          OutlinedButton.icon(
            onPressed: () async {
              // Layar sertifikasi tetap terbuka; saat kembali, refetch agar
              // daftar di detail ikut ter-update.
              await openAuditorSertifikasi(context, ref: auditor.id);
              if (!context.mounted) return;
              ref.invalidate(auditorSertifikasiProvider(auditor.id));
            },
            icon: const Icon(Icons.workspace_premium_outlined, size: 18),
            label: const Text('Kelola Sertifikasi Teknis'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
            ),
          ),
        ],
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

  Future<void> _openUrl(BuildContext context, String url) => openFileUrl(
        context,
        url,
        invalidMessage: 'URL tidak valid',
        failureMessage: 'Gagal membuka tautan',
      );
}