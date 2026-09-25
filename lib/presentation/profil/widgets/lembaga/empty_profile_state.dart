import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Pull-to-refresh empty state shown when the institution profile has no data.
class EmptyProfileState extends StatelessWidget {
  const EmptyProfileState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
        children: [
          Icon(
            Icons.apartment_outlined,
            size: 56,
            color: AppColors.primary.withValues(alpha: 0.65),
          ),
          const SizedBox(height: 16),
          const Text(
            'Profil lembaga belum tersedia',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Data profil belum dikirim oleh server. Tarik layar untuk memuat ulang.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}