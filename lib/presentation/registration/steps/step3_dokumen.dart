import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/file_utils.dart';
import '../../../data/models/registrasi_model.dart';
import '../../../providers/registrasi_provider.dart';
import '../widgets/document_upload_card.dart';

class Step3Dokumen extends ConsumerWidget {
  const Step3Dokumen({super.key});

  Future<FileItem?> _pick(BuildContext context, List<String> allowed) async {
    final r = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: allowed);
    if (r == null) return null;
    final f = r.files.single;
    if (f.size > FileUtils.maxSizeBytes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ukuran file maksimal 5MB')));
      }
      return null;
    }
    return FileItem(path: f.path ?? '', name: f.name, size: f.size);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final data = ref.watch(registrasiProvider).data;
    final notifier = ref.read(registrasiProvider.notifier);

    Widget card(String key, String label, bool req, List<String> ext) =>
        DocumentUploadCard(
          label: label,
          requiredDoc: req,
          file: data.dokumen[key],
          onPick: () async {
            final file = await _pick(context, ext);
            if (file != null) notifier.setDocument(key, file);
          },
          onRemove: () => notifier.setDocument(key, null),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: ListView(
        children: [
          Text(
            'Dokumen Persyaratan',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          card(
              'akta_badan_hukum', '1. Salinan akta badan hukum', true, ['pdf']),
          Divider(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            height: AppTheme.spacing16,
          ),
          const SizedBox(height: AppTheme.spacing8),
          card(
              'struktur_manajemen',
              '2. Struktur organisasi dan manajemen LATIK',
              true,
              ['pdf', 'jpg', 'jpeg', 'png']),
          Divider(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            height: AppTheme.spacing16,
          ),
          const SizedBox(height: AppTheme.spacing8),
          card('peraturan_tupoksi', '3. Peraturan tugas pokok/fungsi LATIK',
              false, ['pdf']),
          Divider(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            height: AppTheme.spacing16,
          ),
          const SizedBox(height: AppTheme.spacing8),
          card('surat_akreditasi_kan',
              '4. Surat akreditasi Komite Akreditasi Nasional', true, ['pdf']),
          Divider(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            height: AppTheme.spacing16,
          ),
          const SizedBox(height: AppTheme.spacing8),
          card('nib_bkpm', '5. Nomor Ijin Berusaha dari BKPM', true, ['pdf']),
          Divider(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            height: AppTheme.spacing16,
          ),
          const SizedBox(height: AppTheme.spacing8),
          card('ikatan_kerja_auditor',
              '6. Surat perjanjian ikatan kerja auditor tetap', true, ['pdf']),
          Divider(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            height: AppTheme.spacing16,
          ),
          const SizedBox(height: AppTheme.spacing8),
          card('pernyataan_non_asn',
              '7. Surat pernyataan auditor TIK tetap non-ASN', true, ['pdf']),
          Divider(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            height: AppTheme.spacing16,
          ),
          const SizedBox(height: AppTheme.spacing8),
          card('profil_latik', '8. Dokumen profil LATIK', true, ['pdf']),
          Divider(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            height: AppTheme.spacing16,
          ),
          const SizedBox(height: AppTheme.spacing8),
          card('permohonan_reg_latik',
              '9. Surat Permohonan Registrasi LATIK SPBE', true, ['pdf']),
          Divider(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            height: AppTheme.spacing16,
          ),
          const SizedBox(height: AppTheme.spacing8),
          card(
              'permohonan_reg_auditor',
              '10. Surat Permohonan Registrasi Auditor TIK SPBE',
              true,
              ['pdf']),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => notifier.setStep(1),
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
                    final required = [
                      'akta_badan_hukum',
                      'struktur_manajemen',
                      'surat_akreditasi_kan',
                      'nib_bkpm',
                      'ikatan_kerja_auditor',
                      'pernyataan_non_asn',
                      'profil_latik',
                      'permohonan_reg_latik',
                      'permohonan_reg_auditor',
                    ];
                    final ok = required.every((e) => data.dokumen[e] != null);
                    if (!ok) {
                      _showErrorSnackBar(
                          context, 'Dokumen wajib belum lengkap');
                      return;
                    }
                    notifier.setStep(3); // Next step
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
