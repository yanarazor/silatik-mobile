import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/invoice_model.dart';

/// Transaction type as a filled pill, styled like the status chip: a tinted
/// background that hugs the label (not a full-width block).
class TypeBadge extends StatelessWidget {
  const TypeBadge({super.key, required this.type});

  final InvoiceType type;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (type) {
      InvoiceType.registrasiLatik ||
      InvoiceType.perpanjanganLatik =>
        (
          AppColors.primary.withValues(alpha: 0.1),
          AppColors.primary,
        ),
      InvoiceType.penambahanAuditor ||
      InvoiceType.perpanjanganAuditor ||
      InvoiceType.registrasiAuditor =>
        (
          AppColors.warning.withValues(alpha: 0.15),
          const Color(0xFFB45309),
        ),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          type.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: fg,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Payment status pill with a colored dot.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      InvoiceStatus.lunas => (
          AppColors.success.withValues(alpha: 0.15),
          const Color(0xFF1B5E20),
        ),
      InvoiceStatus.terhutang => (
          AppColors.error.withValues(alpha: 0.1),
          AppColors.error,
        ),
      InvoiceStatus.kadaluarsa => (
          AppColors.warning.withValues(alpha: 0.15),
          const Color(0xFFB45309),
        ),
      InvoiceStatus.lainnya => (
          const Color(0xFFF1F5F9),
          const Color(0xFF475569),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable status chip used inside the filter sheet.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : const Color(0xFFF5F7FA),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? Colors.transparent : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Selectable transaction-type row used inside the filter sheet.
class TypeOption extends StatelessWidget {
  const TypeOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.1)
            : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color:
                          selected ? AppColors.primary : const Color(0xFF1A1A2E),
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_rounded,
                      size: 18, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}