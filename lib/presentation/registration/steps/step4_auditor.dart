import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auditor_provider.dart';
import '../../../providers/registrasi_provider.dart';
import '../widgets/auditor_card.dart';
import '../widgets/auditor_form_sheet.dart';

class Step4Auditor extends ConsumerWidget {
  const Step4Auditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auditors = ref.watch(auditorProvider);
    final auditorNotifier = ref.read(auditorProvider.notifier);
    final regNotifier = ref.read(registrasiProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: constraints.maxHeight,
        width: constraints.maxWidth,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Data Auditor',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton.icon(
                      onPressed: () => showAuditorSheet(context, ref),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Tambah'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLarge),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing16,
                          vertical: AppTheme.spacing8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),
              if (auditors.isNotEmpty)
                ...auditors.map((auditor) => AuditorCard(
                      auditor: auditor,
                      onDelete: () => auditorNotifier.remove(auditor.id),
                    )),
              if (auditors.isEmpty) const SizedBox(height: AppTheme.spacing16),
              InkWell(
                onTap: () => showAuditorSheet(context, ref),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTheme.spacing24),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Center(
                    child: Text(
                      'Tambahkan auditor lainnya',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => regNotifier.setStep(2),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacing12),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: const Text('Kembali'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (auditors.isEmpty) {
                          _showErrorSnackBar(
                              context, 'Minimal 1 auditor wajib ditambahkan');
                          return;
                        }
                        regNotifier.setStep(4);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacing12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: const Text('Selanjutnya'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

void showAuditorSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => AuditorFormSheet(
        onSave: (a) => ref.read(auditorProvider.notifier).add(a)),
  );
}
