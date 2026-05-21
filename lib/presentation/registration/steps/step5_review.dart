import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/registrasi_provider.dart';
import '../../dashboard/dashboard_screen.dart';

class Step5Review extends ConsumerWidget {
  const Step5Review({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(registrasiProvider);
    final data = state.data;
    final notifier = ref.read(registrasiProvider.notifier);

    if (state.referenceNumber != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing20),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 72,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                'Permohonan Berhasil Dikirim',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Text(
                  'Nomor Referensi: ${state.referenceNumber}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                'Tim BRIN akan memverifikasi dalam 14 hari kerja',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing24),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing32,
                    vertical: AppTheme.spacing12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: const Text('Ke Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: ListView(
        children: [
          _buildExpansionTile(
            context,
            title: 'Data Lembaga',
            children: [
              ListTile(
                title: Text(
                  data.lembaga?.nama ?? '-',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text('NIB: ${data.lembaga?.nib ?? '-'}'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          _buildExpansionTile(
            context,
            title: 'Data Akreditasi',
            children: [
              ListTile(
                title: Text(
                  'No Sertifikat: ${data.nomorKan}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${AppFormatters.formatDate(data.terbitKan)} - ${AppFormatters.formatDate(data.berakhirKan)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          _buildExpansionTile(
            context,
            title: 'Dokumen',
            children: data.dokumen.entries
                .map((e) => ListTile(
                      title: Text(
                        e.key,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(e.value?.name ?? '-'),
                      leading: const Icon(Icons.description,
                          color: AppColors.primary),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppTheme.spacing8),
          _buildExpansionTile(
            context,
            title: 'Daftar Auditor',
            children: data.auditors
                .map((e) => ListTile(
                      title: Text(
                        e.nama,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(e.kompetensi.join(', ')),
                      leading:
                          const Icon(Icons.person, color: AppColors.primary),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppColors.warning.withOpacity(0.2)),
            ),
            child: CheckboxListTile(
              value: data.pernyataan,
              onChanged: (v) => notifier.setPernyataan(v ?? false),
              title: Text(
                'Saya menyatakan bahwa seluruh data dan dokumen yang diberikan adalah benar dan dapat dipertanggungjawabkan',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              checkColor: Colors.white,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => notifier.setStep(3),
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
                  onPressed: data.pernyataan
                      ? () async {
                          final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Konfirmasi'),
                                  content:
                                      const Text('Kirim permohonan sekarang?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Kirim'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                          if (!ok) return;
                          await notifier.submit();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.textSecondary.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing12),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  child: state.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Kirim Permohonan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionTile(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        collapsedBackgroundColor: AppColors.primary.withOpacity(0.02),
        backgroundColor: AppColors.primary.withOpacity(0.05),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        children: children,
      ),
    );
  }
}
