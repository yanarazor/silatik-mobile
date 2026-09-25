import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/invoice_model.dart';
import 'transaksi_filter_button.dart';
import 'transaction_badges.dart';

/// Result returned by the filter bottom sheet.
class FilterResult {
  const FilterResult(this.status, this.type);

  final InvoiceStatus? status;
  final InvoiceType? type;
}

/// Bottom sheet with status chips + type chips. Selections are pending until
/// "Terapkan Filter"; "Reset" clears both. Mirrors the HTML filter sheet, but
/// type options exclude Registrasi Auditor (not offered per the brief).
class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key, required this.status, required this.type});

  final InvoiceStatus? status;
  final InvoiceType? type;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late InvoiceStatus? _status = widget.status;
  late InvoiceType? _type = widget.type;

  static const _statusOptions = <InvoiceStatus>[
    InvoiceStatus.terhutang,
    InvoiceStatus.lunas,
    InvoiceStatus.kadaluarsa,
  ];

  // Registrasi Auditor (code 3) is intentionally not a filter option.
  static const _typeOptions = <InvoiceType>[
    InvoiceType.registrasiLatik,
    InvoiceType.perpanjanganLatik,
    InvoiceType.perpanjanganAuditor,
    InvoiceType.penambahanAuditor,
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5EAF3),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.tune_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Filter Transaksi',
                    style: TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const SectionLabel('Status Transaksi'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusChip(
                  label: 'Semua Status',
                  selected: _status == null,
                  onTap: () => setState(() => _status = null),
                ),
                for (final s in _statusOptions)
                  StatusChip(
                    label: s.label,
                    selected: _status == s,
                    onTap: () => setState(() => _status = s),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const SectionLabel('Jenis Transaksi'),
            const SizedBox(height: 8),
            TypeOption(
              label: 'Semua Jenis',
              selected: _type == null,
              onTap: () => setState(() => _type = null),
            ),
            for (final t in _typeOptions)
              TypeOption(
                label: t.label,
                selected: _type == t,
                onTap: () => setState(() => _type = t),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(const FilterResult(null, null)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      foregroundColor: const Color(0xFF1A1A2E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Reset',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context)
                        .pop(FilterResult(_status, _type)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Terapkan Filter',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}