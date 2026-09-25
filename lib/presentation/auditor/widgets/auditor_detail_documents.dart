import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/url_opener.dart';
import '../../../data/models/auditor_document.dart';
import '../../../data/models/auditor_model.dart';
import '../../../providers/auditor_provider.dart';
import 'detail_section.dart';

/// Auditor document list with loading / error / empty states.
class AuditorDetailDocuments extends ConsumerWidget {
  const AuditorDetailDocuments({super.key, required this.auditor});

  final AuditorModel auditor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(auditorDocsProvider(auditor.id));
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
                  ref.invalidate(auditorDocsProvider(auditor.id)),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    final docs = docsAsync.valueOrNull ?? [];
    if (docs.isEmpty) {
      return const DetailEmptySection('Belum ada berkas dokumen');
    }
    return Column(
      children: [
        for (var i = 0; i < docs.length; i++) ...[
          _buildDocumentRow(context, docs[i]),
          if (i != docs.length - 1) const DetailSectionDivider(),
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
      status = DetailChip(
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

  Future<void> _openUrl(BuildContext context, String url) => openFileUrl(
        context,
        url,
        invalidMessage: 'URL tidak valid',
        failureMessage: 'Gagal membuka tautan',
      );
}