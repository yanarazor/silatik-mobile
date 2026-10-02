import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';

/// STR validity card on the dashboard. Shows the remaining validity window of
/// the LATIK STR with day-count-based coloring, or a neutral state when no STR
/// date is available.
class StrValidityCard extends StatelessWidget {
  const StrValidityCard({super.key, required this.strTanggalAkhir});

  final DateTime? strTanggalAkhir;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final String value;
    final Color valueColor;
    String? subLine;

    if (strTanggalAkhir == null) {
      value = 'Belum memiliki STR';
      valueColor = AppColors.primary;
    } else {
      final days = strTanggalAkhir!.difference(now).inDays;
      subLine = 'Berlaku s/d ${AppFormatters.formatDate(strTanggalAkhir)}';
      if (days < 0) {
        value = 'STR telah kadaluarsa';
        valueColor = AppColors.error;
      } else if (days <= 30) {
        value = '$days hari lagi';
        valueColor = AppColors.warning;
      } else {
        value = '$days hari lagi';
        valueColor = AppColors.primary;
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4ECF7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2D5C).withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MASA BERLAKU STR LATIK',
                  style: TextStyle(
                    color: Color(0xFF5B6880),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                if (subLine != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subLine,
                    style: const TextStyle(
                      color: Color(0xFF8A96AA),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
