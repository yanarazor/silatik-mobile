import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/registrasi_model.dart';
import '../../providers/auditor_form_provider.dart';
import 'cached_remote_image.dart';

class DokumenUploadCard extends ConsumerWidget {
  const DokumenUploadCard({
    super.key,
    required this.title,
    required this.requiredDoc,
    required this.file,
    required this.onPick,
    required this.onPreview,
    this.leadingIcon = Icons.picture_as_pdf,
    this.leadingColor = AppColors.error,
    this.formatHint = 'Format PDF (maks. 10 MB)',
    this.imageThumbnail = false,
    this.extraFields,
  });

  final String title;
  final bool requiredDoc;
  final FileItem? file;
  final VoidCallback onPick;

  final VoidCallback onPreview;

  final IconData leadingIcon;
  final Color leadingColor;

  final String formatHint;

  final bool imageThumbnail;

  final Widget? extraFields;

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
          if (extraFields != null) ...[
            const SizedBox(height: AppTheme.spacing12),
            extraFields!,
          ],
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
              formatHint,
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
                _leadingTile(),
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

  Widget _leadingTile() {
    if (imageThumbnail && file != null) {
      final path = file!.path;
      final child = _isWebUrl
          ? CachedRemoteImage(
              url: path,
              width: 40,
              height: 40,
              fallback: Icon(leadingIcon, color: leadingColor, size: 22),
            )
          : Image.file(
              File(path),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(leadingIcon, color: leadingColor, size: 22),
            );
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: SizedBox(width: 40, height: 40, child: child),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: leadingColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Icon(leadingIcon, color: leadingColor, size: 22),
    );
  }

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

class NomorTanggalFields extends StatelessWidget {
  const NomorTanggalFields({
    super.key,
    required this.showNomor,
    required this.showTanggal,
    required this.nomor,
    required this.tanggal,
    required this.onNomor,
    required this.onTanggal,
  });

  final bool showNomor;
  final bool showTanggal;
  final String nomor;
  final DateTime? tanggal;
  final ValueChanged<String> onNomor;
  final VoidCallback onTanggal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showNomor) ...[
          _label(theme, 'Nomor'),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: nomor,
            onChanged: onNomor,
            decoration: _inputDecoration('Masukkan nomor dokumen'),
          ),
          const SizedBox(height: AppTheme.spacing8),
        ],
        if (showTanggal) ...[
          _label(theme, 'Tanggal'),
          const SizedBox(height: 4),
          InkWell(
            onTap: onTanggal,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: InputDecorator(
              decoration: _inputDecoration('Pilih tanggal').copyWith(
                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
              ),
              child: Text(
                tanggal != null ? AppFormatters.formatDate(tanggal) : 'Pilih tanggal',
                style: TextStyle(
                  color: tanggal != null
                      ? const Color(0xFF111827)
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _label(ThemeData theme, String text) => RichText(
        text: TextSpan(
          text: text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          children: const [
            TextSpan(text: ' *', style: TextStyle(color: AppColors.error)),
          ],
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      );
}
