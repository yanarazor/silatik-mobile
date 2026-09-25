import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Bold form field label with an optional required marker.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.isRequired = true});

  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
          bottom: AppTheme.spacing8, top: AppTheme.spacing16),
      child: RichText(
        text: TextSpan(
          text: text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          children: isRequired
              ? [
                  TextSpan(
                    text: ' *',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: AppColors.error),
                  ),
                ]
              : const [],
        ),
      ),
    );
  }
}