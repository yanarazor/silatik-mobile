import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class StatusCard extends StatelessWidget {
  final String status;
  const StatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    var color = AppColors.warning;
    var icon = Icons.hourglass_top_rounded;

    if (status.contains('Review')) {
      color = AppColors.primary;
      icon = Icons.search_rounded;
    }
    if (status.contains('Terdaftar')) {
      color = AppColors.success;
      icon = Icons.verified_rounded;
    }
    if (status.contains('Ditolak')) {
      color = AppColors.error;
      icon = Icons.cancel_rounded;
    }

    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Registrasi',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    status,
                    style: textTheme.labelLarge?.copyWith(
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Aktif',
                style: textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
