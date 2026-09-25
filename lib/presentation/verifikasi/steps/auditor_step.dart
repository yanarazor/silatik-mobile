import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/auditor_model.dart';
import '../../../providers/latik_verifikasi_provider.dart';
import '../../shared/auditor_check_tile.dart';

/// Langkah 3 — pilih auditor (checkbox). Gate: >=1 dipilih DAN >=1 Tetap.
class AuditorStep extends ConsumerWidget {
  const AuditorStep({
    super.key,
    required this.latikRef,
    required this.auditorsAsync,
    required this.onRetry,
    required this.onBack,
    required this.onNext,
  });

  final String latikRef;
  final AsyncValue<List<AuditorModel>> auditorsAsync;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(latikVerifikasiProvider(latikRef).notifier);
    // watch supaya checkbox rerender saat seleksi berubah.
    ref.watch(latikVerifikasiProvider(latikRef));

    return auditorsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gagal memuat auditor'),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
      data: (all) {
        if (all.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada auditor. Tambahkan auditor terlebih dahulu.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: all.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final a = all[i];
                    return AuditorCheckTile(
                      auditor: a,
                      checked: notifier.isSelected(a),
                      onChanged: (on) => notifier.toggle(a, on ?? false),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacing12),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium)),
                      ),
                      child: const Text('Kembali'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacing12),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium)),
                      ),
                      child: const Text('Selanjutnya'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}