import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/auditor_model.dart';
import '../../../../providers/auditor_ext_provider.dart';
import 'auditor_doc_row.dart';

/// Step 1 — hub dokumen. Satu baris per auditor + badge kelengkapan; tap buka
/// sub-halaman pengisian. Guard evenness ditampilkan sebagai error + retry.
class DocHubStep extends ConsumerWidget {
  const DocHubStep({
    super.key,
    required this.refExt,
    required this.selected,
    required this.state,
    required this.onOpen,
    required this.onRetry,
    required this.onNext,
  });

  final String refExt;
  final List<AuditorModel> selected;
  final AuditorExtState state;
  final void Function(int index) onOpen;
  final VoidCallback onRetry;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.watch(auditorExtProvider(refExt).notifier);

    if (state.submitting && state.flatDocs.isEmpty && state.docError == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.docError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                state.docError!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    final allComplete = notifier.allComplete;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dokumen per Auditor',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Lengkapi dokumen untuk setiap auditor terpilih.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Expanded(
            child: ListView.separated(
              itemCount: selected.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTheme.spacing8),
              itemBuilder: (_, i) {
                final complete = notifier.isAuditorComplete(i);
                return AuditorDocRow(
                  nama: selected[i].nama,
                  complete: complete,
                  onTap: () => onOpen(i),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          ElevatedButton(
            onPressed: allComplete ? onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
            ),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
  }
}