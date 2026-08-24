import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const StepIndicator({super.key, required this.current, this.total = 5});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final activeOrDone = i <= current;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing4),
            height: 6,
            decoration: BoxDecoration(
              color: activeOrDone
                  ? AppColors.accent
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
        );
      }),
    );
  }
}
