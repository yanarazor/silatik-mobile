import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/file_utils.dart';
import '../../../data/models/registrasi_model.dart';
import '../../../providers/auditor_form_provider.dart';

class AuditorDokumenCard extends ConsumerWidget {
  const AuditorDokumenCard({
    super.key,
    required this.title,
    required this.requiredDoc,
    required this.file,
    required this.onPick,
    required this.onPreview,
  });

  final String title;
  final bool requiredDoc;
  final FileItem? file;
  final VoidCallback onPick;

  /// Dipanggil saat "Pratinjau" ditekan (buka viewer PDF/URL bersama).
  final VoidCallback onPreview;

  bool get _isWebUrl {
    final p = file?.path.trim().toLowerCase() ?? '';
    return p.startsWith('http://') || p.startsWith('https://');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              children: requiredDoc
                  ? const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ]
                  : const [],
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          file == null ? _uploadZone(theme) : _fileBox(context, ref, theme),
        ],
      ),
    );
  }

  Widget _uploadZone(ThemeData theme) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing24),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_upload_outlined,
                  color: AppColors.primary, size: 26),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Pilih Berkas',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Format PDF (maks. 10 MB)',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fileBox(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: const Icon(Icons.picture_as_pdf,
                      color: AppColors.error, size: 22),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file!.name.isEmpty ? 'dokumen' : file!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      _sizeLine(ref, theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: AppTheme.spacing8),
          Row(
            children: [
              Expanded(
                child: _smallButton(
                  icon: Icons.visibility_outlined,
                  label: 'Pratinjau',
                  color: AppColors.primary,
                  onTap: onPreview,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              Expanded(
                child: _smallButton(
                  icon: Icons.sync,
                  label: 'Ganti',
                  color: AppColors.textSecondary,
                  onTap: onPick,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Baris ukuran: file lokal pakai size langsung; file server ambil dari
  /// header content-length (kalau ada). Kalau tak ada, baris disembunyikan.
  Widget _sizeLine(WidgetRef ref, ThemeData theme) {
    final localSize = file!.size;
    if (!_isWebUrl && localSize > 0) {
      return Text(
        FileUtils.formatBytes(localSize),
        style: theme.textTheme.bodySmall
            ?.copyWith(color: AppColors.textSecondary),
      );
    }
    if (_isWebUrl) {
      final sizeAsync = ref.watch(fileContentLengthProvider(file!.path));
      final size = sizeAsync.valueOrNull;
      if (size != null) {
        return Text(
          FileUtils.formatBytes(size),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _smallButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: color),
      label: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      ),
    );
  }
}
