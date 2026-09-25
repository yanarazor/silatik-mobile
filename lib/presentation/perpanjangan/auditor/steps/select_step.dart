import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/auditor_model.dart';
import '../../../../providers/auditor_provider.dart';
import '../../../shared/auditor_check_tile.dart';

/// Step 0 — pilih auditor. Checkbox hanya untuk yang `editableRenew`.
class SelectStep extends ConsumerWidget {
  const SelectStep({
    super.key,
    required this.selected,
    required this.busy,
    required this.onToggle,
    required this.onNext,
  });

  final List<AuditorModel> selected;

  /// True saat menyimpan pilihan + memuat dokumen (POST /auditorext berjalan).
  final bool busy;
  final void Function(AuditorModel, bool?) onToggle;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(auditorListProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gagal memuat auditor'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(auditorListProvider),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
      data: (all) {
        final renewable = all.where((a) => !a.editableRenew).toList();
        if (renewable.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 48,
                      color: AppColors.primary.withValues(alpha: 0.6)),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada auditor yang dapat diperpanjang saat ini.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Auditor',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Pilih auditor yang akan diperpanjang registrasinya.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacing16),
              Expanded(
                child: ListView.separated(
                  itemCount: renewable.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppTheme.spacing8),
                  itemBuilder: (_, i) {
                    final a = renewable[i];
                    final on = selected.any((s) => s.id == a.id);
                    return AuditorCheckTile(
                      auditor: a,
                      checked: on,
                      onChanged: (v) => onToggle(a, v),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              ElevatedButton(
                onPressed: (selected.isEmpty || busy) ? null : onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium)),
                ),
                child: busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Lanjut (${selected.length} dipilih)'),
              ),
            ],
          ),
        );
      },
    );
  }
}