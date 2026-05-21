import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/file_utils.dart';
import '../../../data/models/registrasi_model.dart';

class DocumentUploadCard extends StatelessWidget {
  final String label;
  final bool requiredDoc;
  final FileItem? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const DocumentUploadCard({
    super.key,
    required this.label,
    required this.requiredDoc,
    required this.file,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canView = file != null && _isWebUrl(file!.path);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              children: requiredDoc
                  ? [
                      TextSpan(
                        text: ' *',
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    ]
                  : [],
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          if (file == null)
            Text(
              'Belum diunggah',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            Text(
              '${file?.name.isNotEmpty == true ? file?.name : 'dokumen'} - ${FileUtils.formatBytes(file?.size ?? 0)}',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: AppTheme.spacing8),
          Align(
            alignment: Alignment.centerLeft,
            child: file == null
                ? OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                    label: const Text('Unggah'),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canView)
                        IconButton(
                          icon: const Icon(Icons.open_in_new,
                              color: AppColors.primary, size: 20),
                          onPressed: () => _openUrl(context, file!.path),
                          constraints:
                              const BoxConstraints(minWidth: 40, minHeight: 40),
                          padding: EdgeInsets.zero,
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.primary, size: 20),
                        onPressed: onPick,
                        constraints:
                            const BoxConstraints(minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error, size: 20),
                        onPressed: onRemove,
                        constraints:
                            const BoxConstraints(minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  bool _isWebUrl(String value) {
    final text = value.trim().toLowerCase();
    return text.startsWith('http://') || text.startsWith('https://');
  }

  Future<void> _openUrl(BuildContext context, String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      _showSnack(context, 'URL dokumen tidak valid');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _showSnack(context, 'Gagal membuka dokumen');
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
