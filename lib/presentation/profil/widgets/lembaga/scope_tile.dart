import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Checkbox row for one registration scope. Disabled when [onChanged] is null.
class ScopeTile extends StatelessWidget {
  const ScopeTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;
    return CheckboxListTile(
      value: value,
      onChanged: disabled ? null : (v) => onChanged!(v ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      title: Text(
        label,
        style: TextStyle(
          color: disabled ? AppColors.textSecondary : AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: disabled
          ? const Text('Belum tersedia',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11))
          : null,
    );
  }
}