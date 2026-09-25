import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Toolbar Filter button with a dot when a filter is active.
/// Filled tonal Filter button; when filters are applied it turns solid primary
/// and shows a count badge instead of a bare dot.
class FilterButton extends StatelessWidget {
  const FilterButton({super.key, required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = activeCount > 0;
    final bg =
        active ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08);
    final fg = active ? Colors.white : AppColors.primary;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                'Filter',
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 7),
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$activeCount',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bold section heading used inside the filter sheet.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF1A1A2E),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}