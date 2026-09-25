import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'berkas_colors.dart';
import 'filter_chip.dart';

/// Summary card: document totals + verification filter chips.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.total,
    required this.verified,
    required this.pending,
    required this.filter,
    required this.onFilter,
  });

  final int total;
  final int verified;
  final int pending;
  final BerkasFilter filter;
  final ValueChanged<BerkasFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(color: berkasCardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C2D5C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: berkasBlueTint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: berkasBlueTintBorder),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total Dokumen Legalitas',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Kelengkapan berkas profil Lembaga SILATIK',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: berkasCardDivider),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DocFilterChip(
                label: 'Semua ($total)',
                selected: filter == BerkasFilter.semua,
                onTap: () => onFilter(BerkasFilter.semua),
              ),
              DocFilterChip(
                label: 'Terverifikasi ($verified)',
                dotColor: berkasGreen,
                selected: filter == BerkasFilter.terverifikasi,
                onTap: () => onFilter(BerkasFilter.terverifikasi),
              ),
              DocFilterChip(
                label: 'Belum Diverifikasi ($pending)',
                dotColor: const Color(0xFF737781),
                selected: filter == BerkasFilter.belum,
                onTap: () => onFilter(BerkasFilter.belum),
              ),
            ],
          ),
        ],
      ),
    );
  }
}