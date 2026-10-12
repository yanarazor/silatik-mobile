import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.value,
    required this.onPick,
    this.hint = 'Pilih tanggal',
    this.prefixIcon = Icons.cake_outlined,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final String hint;
  final IconData prefixIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null;
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          firstDate: DateTime(1940),
          lastDate: DateTime.now(),
          initialDate: value ?? DateTime(1990),
        );
        if (date != null) onPick(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: Icon(prefixIcon),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          hasValue ? value!.toString().split(' ').first : hint,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: hasValue ? AppColors.textPrimary : theme.hintColor,
          ),
        ),
      ),
    );
  }
}
