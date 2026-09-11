import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// One selectable filter option for [HeaderFilterPills]. [count] renders inline
/// as "(n)" when non-null.
class HeaderFilterOption<T> {
  const HeaderFilterOption({
    required this.value,
    required this.label,
    this.count,
  });

  final T value;
  final String label;
  final int? count;
}

/// Horizontal scroll of filter pills styled for the blue header band.
///
/// Shared so header-level filters look identical across screens (auditor list,
/// notifikasi, …): white when selected, translucent white otherwise, count
/// shown inline as "(n)".
class HeaderFilterPills<T> extends StatelessWidget {
  const HeaderFilterPills({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<HeaderFilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final option = options[i];
          final isSelected = option.value == selected;
          final label = option.count != null
              ? '${option.label} (${option.count})'
              : option.label;
          return Semantics(
            button: true,
            selected: isSelected,
            child: GestureDetector(
              onTap: () {
                if (!isSelected) onSelected(option.value);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primaryLight
                        : Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
