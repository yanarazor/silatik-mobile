import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/auditor_model.dart';
import '../../shared/auditor_check_tile.dart';

/// Auditor multi-selection step shared by extension and add-auditor revisions.
class AuditorRevisionSelectStep extends StatelessWidget {
  const AuditorRevisionSelectStep({
    super.key,
    required this.auditors,
    required this.selectedIds,
    required this.onToggle,
    required this.onNext,
  });

  final List<AuditorModel> auditors;
  final Set<String> selectedIds;
  final void Function(String id, bool selected) onToggle;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.checklist_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${selectedIds.length} dari ${auditors.length} auditor dipilih',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              for (final auditor in auditors) ...[
                AuditorCheckTile(
                  auditor: auditor,
                  checked: selectedIds.contains(auditor.id),
                  onChanged: (value) => onToggle(auditor.id, value == true),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: selectedIds.isEmpty ? null : onNext,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                'Lanjut ke Dokumen (${selectedIds.length} Auditor)',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
