import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/latik_profile.dart';
import 'lembaga_cards.dart';
import 'lembaga_colors.dart';

/// Two summary cards: total auditors and verification status.
class StatsRow extends StatelessWidget {
  const StatsRow({super.key, required this.data, required this.auditorCount});

  final LatikProfile data;
  final int auditorCount;

  @override
  Widget build(BuildContext context) {
    final count = data.auditorCount > 0 ? data.auditorCount : auditorCount;
    final statusValue =
        data.statusText.isEmpty ? 'Belum Terverifikasi' : data.statusText;
    final verified = data.isVerified;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: StatCard(
              iconBg: lembagaBlueTint,
              iconColor: AppColors.primary,
              icon: Icons.group_rounded,
              label: 'Total Auditor',
              value: '$count Orang',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: StatCard(
              iconBg: verified
                  ? lembagaGreen.withValues(alpha: 0.12)
                  : lembagaAmber.withValues(alpha: 0.12),
              iconColor: verified ? lembagaGreen : lembagaAmber,
              icon: verified ? Icons.verified_rounded : Icons.pending_rounded,
              label: 'Status Verifikasi',
              value: statusValue,
              valueColor: verified ? lembagaGreen : lembagaAmber,
              valueMaxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}