import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/auditor_model.dart';

class AuditorCard extends StatelessWidget {
  final AuditorModel auditor;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const AuditorCard({
    super.key,
    required this.auditor,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    String initials = '';
    if (auditor.nama.isNotEmpty) {
      final names = auditor.nama.split(' ');
      if (names.length >= 2) {
        initials = '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else {
        initials = (auditor.nama.length > 1 ? auditor.nama.substring(0, 2) : auditor.nama)
            .toUpperCase();
      }
    }

    String maskedNik = auditor.nik;
    if (maskedNik.length > 4) {
      maskedNik = '${'*' * (maskedNik.length - 4)}${maskedNik.substring(maskedNik.length - 4)}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auditor.nama,
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        auditor.email.isEmpty ? 'NIK: $maskedNik' : auditor.email,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            Wrap(
              spacing: AppTheme.spacing8,
              runSpacing: AppTheme.spacing8,
              children: [
                _Badge(text: auditor.statusLabel, color: const Color(0xFF6D7684)),
                _Badge(
                  text: auditor.activeLabel,
                  color: auditor.activeLabel == 'Aktif' ? AppColors.success : AppColors.error,
                ),
                _Badge(
                  text: auditor.verificationLabel,
                  color: auditor.verificationLabel == 'Sudah Verifikasi'
                      ? AppColors.success
                      : AppColors.error,
                ),
              ],
            ),
            if (auditor.strTanggalAkhir != null) ...[
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Akhir STR: ${auditor.strTanggalAkhir!.toIso8601String().split('T').first}',
                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
            if (auditor.kompetensi.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacing12),
              Wrap(
                spacing: AppTheme.spacing8,
                runSpacing: AppTheme.spacing8,
                children: auditor.kompetensi
                    .map(
                      (e) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing12,
                          vertical: AppTheme.spacing4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          e,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
