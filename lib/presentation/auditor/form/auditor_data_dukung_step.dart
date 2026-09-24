import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/url_opener.dart';
import '../../../data/models/auditor_dokumen_def.dart';
import '../../../data/models/registrasi_model.dart';
import '../../../providers/auditor_form_provider.dart';
import '../../shared/dokumen_upload_card.dart';
import 'auditor_profil_step.dart' show kAuditorFileMaxBytes;

class AuditorDataDukungStep extends ConsumerWidget {
  const AuditorDataDukungStep({
    super.key,
    required this.formKey,
    required this.onBack,
    required this.onSaved,
  });

  final String? formKey;
  final VoidCallback onBack;
  final VoidCallback onSaved;

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    String field,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;
    final file = result.files.single;
    if (file.size > kAuditorFileMaxBytes) {
      if (context.mounted) {
        _snack(context, 'Ukuran file maksimal 10MB');
      }
      return;
    }
    ref.read(auditorFormProvider(formKey).notifier).setDoc(
          field,
          FileItem(path: file.path ?? '', name: file.name, size: file.size),
        );
  }

  Future<void> _preview(BuildContext context, FileItem doc) async {
    final path = doc.path.trim();
    final isWeb = path.toLowerCase().startsWith('http');
    if (isWeb) {
      // URL server → pakai opener PDF/URL bersama.
      await openFileUrl(context, path);
      return;
    }
    // Berkas lokal yang baru dipilih → buka via aplikasi bawaan.
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && context.mounted) {
      _snack(context, 'Gagal membuka berkas: ${result.message}');
    }
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    List<AuditorDokumenDef> defs,
  ) async {
    final formState = ref.read(auditorFormProvider(formKey));
    final docs = formState.dokumen;
    if (kDebugMode) {
      final p = formState.profil;
      debugPrint('=== DATA DUKUNG SUBMIT (${formState.isSaved ? 'update' : 'create'}) ===');
      debugPrint('ref: ${formState.ref}');
      debugPrint('profil: nama=${p.nama} nik=${p.nik} email=${p.email} '
          'tempat=${p.tempatLahir} tgl=${p.tanggalLahir} phone=${p.phone} '
          'provinsi=${p.provinsi} kabupaten=${p.kabupaten} kodePos=${p.kodePos} '
          'agama=${p.agama} status=${p.status} keterangan=${p.keterangan}');
      debugPrint('foto: ${p.foto?.name} (${p.foto?.path})');
      docs.forEach((field, file) =>
          debugPrint('dokumen[$field] = ${file?.name} (${file?.path})'));
    }
    // Wajib: setiap def file_required harus punya file (lokal baru atau URL lama).
    final missing = defs
        .where((d) => d.fileRequired && docs[d.field] == null)
        .map((d) => d.namaDokumen)
        .toList();
    if (missing.isNotEmpty) {
      _snack(context, 'Dokumen wajib belum lengkap: ${missing.first}');
      return;
    }

    try {
      await ref.read(auditorFormProvider(formKey).notifier).submitProfil();
      if (context.mounted) {
        _snack(context, 'Data auditor tersimpan', error: false);
      }
      onSaved();
    } catch (e) {
      if (context.mounted) _snack(context, 'Gagal menyimpan: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final defsAsync = ref.watch(auditorDokumenDefsProvider);
    final state = ref.watch(auditorFormProvider(formKey));

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: defsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _Retry(
          onRetry: () => ref.invalidate(auditorDokumenDefsProvider),
        ),
        data: (defs) => ListView(
          children: [
            Text(
              'Data Dukung',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Unggah dokumen persyaratan auditor (PDF, maks 10MB).',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppTheme.spacing16),
            for (final def in defs) ...[
              DokumenUploadCard(
                title: def.namaDokumen,
                requiredDoc: def.fileRequired,
                file: state.dokumen[def.field],
                onPick: () => _pick(context, ref, def.field),
                onPreview: () {
                  final doc = state.dokumen[def.field];
                  if (doc != null) _preview(context, doc);
                },
              ),
              const SizedBox(height: AppTheme.spacing16),
            ],
            const SizedBox(height: AppTheme.spacing8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.submitting ? null : onBack,
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
                    onPressed: state.submitting
                        ? null
                        : () => _submit(context, ref, defs),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacing12),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium)),
                    ),
                    child: state.submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(state.isSaved ? 'Simpan Perubahan' : 'Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _snack(BuildContext context, String message, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gagal memuat daftar dokumen'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      );
}
