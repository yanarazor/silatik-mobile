import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'auditor_sertifikasi_screen.dart';

/// Success screen after an auditor is saved (create). Offers adding
/// Technical Certification (optional) or finishing and leaving the form.
class AuditorSuccessScreen extends StatelessWidget {
  const AuditorSuccessScreen({
    super.key,
    required this.auditorRef,
    required this.onFinish,
  });

  /// ref of the auditor that was just saved.
  final String auditorRef;

  /// Called when the user taps Finish (refresh list + leave form).
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 72, color: AppColors.success),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'Auditor berhasil disimpan',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Anda bisa menambahkan Sertifikasi Teknis auditor (opsional) '
            'atau selesaikan sekarang.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacing24),
          ElevatedButton.icon(
            onPressed: () =>
                openAuditorSertifikasi(context, ref: auditorRef),
            icon: const Icon(Icons.workspace_premium_outlined, size: 18),
            label: const Text('Tambah Sertifikasi Teknis'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          OutlinedButton(
            onPressed: onFinish,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
            ),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }
}
