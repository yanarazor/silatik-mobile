import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/latik_profile.dart';
import '../../shared/latik_info_section.dart';
import '../../shared/latik_location_card.dart';

/// Langkah 1 — Data LATIK (baca-saja) + notice PKS. Meniru langkah Data
/// Lembaga pada Perpanjangan LATIK, dengan PksNotice di atas.
class DataStep extends StatelessWidget {
  const DataStep({super.key, required this.profile, required this.onNext});

  final LatikProfile profile;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: ListView(
        children: [
          Text(
            'Data Lembaga',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Periksa data lembaga sebelum melanjutkan. Perubahan data '
            'dilakukan melalui menu Profil Lembaga.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacing16),
          LatikInfoSection(data: profile),
          if (LatikLocationCard.maybeBuild(profile) case final map?) ...[
            const SizedBox(height: AppTheme.spacing16),
            map,
          ],
          const SizedBox(height: AppTheme.spacing24),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
            ),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
  }
}