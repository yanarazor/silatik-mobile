import 'package:flutter/material.dart';

import '../../../data/models/auditor_model.dart';

/// Small chip showing the auditor's employment status label.
class RoleChip extends StatelessWidget {
  const RoleChip({super.key, required this.auditor});

  final AuditorModel auditor;

  @override
  Widget build(BuildContext context) {
    final isTetap = auditor.statusLabel.toLowerCase().contains('tetap');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isTetap ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isTetap ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        auditor.statusLabel,
        style: TextStyle(
          color: isTetap ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}