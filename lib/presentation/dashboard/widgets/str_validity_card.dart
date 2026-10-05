import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/url_opener.dart';

/// STR validity card on the dashboard. Shows the remaining validity window of
/// the LATIK STR with day-count-based coloring, or a neutral state when no STR
/// date is available. Includes an action to open the STR file if available.
class StrValidityCard extends StatelessWidget {
  const StrValidityCard({
    super.key,
    required this.strTanggalAkhir,
    this.fileUrl = '',
  });

  final DateTime? strTanggalAkhir;
  final String fileUrl;

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

    final hasAction = fileUrl.trim().isNotEmpty;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
            ],
          ),
          if (hasAction) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE4ECF7)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => openFileUrl(context, fileUrl),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Buka',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.open_in_new_rounded,
                      size: 15, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
