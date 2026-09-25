import 'package:flutter/material.dart';

/// Verification status pill for an auditor card.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.verificationStatus});

  final int verificationStatus;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg, dotColor) = switch (verificationStatus) {
      1 => (
          'Valid',
          const Color(0xFFECFDF5),
          const Color(0xFF047857),
          const Color(0xFF10B981),
        ),
      2 => (
          'Invalid',
          const Color(0xFFF1F5F9),
          const Color(0xFF475569),
          const Color(0xFF94A3B8),
        ),
      _ => (
          'Belum Verifikasi',
          const Color(0xFFFEF2F2),
          const Color(0xFFB91C1C),
          const Color(0xFFEF4444),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}