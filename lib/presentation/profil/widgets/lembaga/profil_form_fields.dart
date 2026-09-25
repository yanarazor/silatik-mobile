import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../core/constants/app_colors.dart';

/// Read-only input styled to match the reactive form fields.
class ReadOnlyField extends StatelessWidget {
  const ReadOnlyField(this.value, this.icon, {super.key});

  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF1F4F9),
      ),
      child: Text(
        value,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
      ),
    );
  }
}

/// Friendly Indonesian message for a required field, replacing the raw
/// reactive_forms validation key shown under the input.
Map<String, String Function(Object)> requiredMsg(String field) => {
      ValidationMessage.required: (_) => '$field wajib diisi',
    };