import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/profile_menu_provider.dart';
import '../../../shared/latik_info_section.dart';
import '../../../shared/latik_location_card.dart';

/// Langkah 0 — Data LATIK (baca-saja). Menampilkan profil institusi dari
/// [latikProfileProvider]. Belum ada aksi edit di sini (menyusul).
class DataLatikStep extends ConsumerWidget {
  const DataLatikStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(latikProfileProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gagal memuat data lembaga.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(latikProfileProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
      data: (data) => Padding(
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
            LatikInfoSection(data: data),
            if (LatikLocationCard.maybeBuild(data) case final map?) ...[
              const SizedBox(height: AppTheme.spacing16),
              map,
            ],
            const SizedBox(height: AppTheme.spacing24),
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
              ),
              child: const Text('Lanjut'),
            ),
          ],
        ),
      ),
    );
  }
}