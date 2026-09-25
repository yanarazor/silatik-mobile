import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'pengguna_colors.dart';

/// Role pill with an icon chosen from the role label.
class RoleChip extends StatelessWidget {
  const RoleChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    final IconData icon;
    if (lower.contains('auditor') ||
        lower.contains('akreditasi') ||
        lower.contains('pic')) {
      icon = Icons.verified_user_rounded;
    } else if (lower.contains('latik') || lower.contains('operator')) {
      icon = Icons.security_rounded;
    } else {
      icon = Icons.badge_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: penggunaChipBg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: penggunaChipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}