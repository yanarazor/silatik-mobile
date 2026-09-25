import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Compact "Label: value" line used inside the LATIK summary card.
class SummaryLine extends StatelessWidget {
  const SummaryLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}