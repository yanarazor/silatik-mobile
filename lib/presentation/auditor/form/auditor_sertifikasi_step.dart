import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/registrasi_model.dart';
import '../../../providers/auditor_form_provider.dart';
import 'auditor_profil_step.dart' show kAuditorFileMaxBytes;

/// Step 2 — Sertifikasi Teknis. Terkunci sampai auditor tersimpan (punya ref).
/// Tiap sertifikat disimpan satu per satu ke /auditor/simpansertifikasiteknis.
class AuditorSertifikasiStep extends ConsumerStatefulWidget {
  const AuditorSertifikasiStep({
    super.key,
    required this.formKey,
    required this.onBack,
    required this.onFinish,
  });

  final String? formKey;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  @override
  ConsumerState<AuditorSertifikasiStep> createState() =>
      _AuditorSertifikasiStepState();
}

class _AuditorSertifikasiStepState
    extends ConsumerState<AuditorSertifikasiStep> {
  final _form = FormGroup({
    'nama_pelatihan': FormControl<String>(validators: [Validators.required]),
    'lembaga': FormControl<String>(validators: [Validators.required]),
  });
  int? _tahun;
  FileItem? _file;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;
    final file = result.files.single;
    if (file.size > kAuditorFileMaxBytes) {
      _snack('Ukuran file maksimal 10MB');
      return;
    }
    setState(() => _file =
        FileItem(path: file.path ?? '', name: file.name, size: file.size));
  }

  Future<void> _add() async {
    _form.markAllAsTouched();
    if (_form.invalid) {
      _snack('Nama pelatihan dan lembaga wajib diisi');
      return;
    }
    if (_tahun == null) {
      _snack('Tahun wajib dipilih');
      return;
    }
    if (_file == null) {
      _snack('File sertifikat (PDF) wajib diunggah');
      return;
    }
    try {
      await ref.read(auditorFormProvider(widget.formKey).notifier).addSertifikat(
            namaPelatihan: _form.control('nama_pelatihan').value ?? '',
            tahun: _tahun.toString(),
            lembaga: _form.control('lembaga').value ?? '',
            sertifikatFile: _file!,
          );
      _form.reset();
      setState(() {
        _tahun = null;
        _file = null;
      });
      _snack('Sertifikat ditambahkan', error: false);
    } catch (e) {
      _snack('Gagal menambah sertifikat: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(auditorFormProvider(widget.formKey));

    if (!state.isSaved) {
      return _Locked(onBack: widget.onBack);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: ListView(
        children: [
          Text(
            'Sertifikasi Teknis',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Tambahkan sertifikat pelatihan teknis (opsional, bisa lebih dari satu).',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacing16),
          if (state.certificates.isNotEmpty) ...[
            for (final c in state.certificates)
              Card(
                margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
                child: ListTile(
                  leading:
                      const Icon(Icons.workspace_premium_outlined,
                          color: AppColors.primary),
                  title: Text(c.nama),
                  subtitle: Text([c.lembaga, c.tahun]
                      .where((e) => e.isNotEmpty)
                      .join(' • ')),
                ),
              ),
            const SizedBox(height: AppTheme.spacing8),
          ],
          ReactiveForm(
            formGroup: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ReactiveTextField(
                  formControlName: 'nama_pelatihan',
                  decoration: const InputDecoration(
                    labelText: 'Nama Pelatihan/Sertifikat*',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                ReactiveTextField(
                  formControlName: 'lembaga',
                  decoration: const InputDecoration(
                    labelText: 'Lembaga Penerbit*',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                _tahunPicker(theme),
                const SizedBox(height: AppTheme.spacing12),
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: Text(_file == null
                      ? 'Unggah Sertifikat (PDF)*'
                      : _file!.name),
                ),
                const SizedBox(height: AppTheme.spacing12),
                ElevatedButton.icon(
                  onPressed: state.submitting ? null : _add,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Sertifikat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
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
                  onPressed: widget.onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium)),
                  ),
                  child: const Text('Selesai'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tahunPicker(ThemeData theme) {
    final now = DateTime.now().year;
    return DropdownButtonFormField<int>(
      initialValue: _tahun,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Tahun*',
        prefixIcon: Icon(Icons.calendar_today_outlined),
      ),
      items: [
        for (var y = now; y >= now - 40; y--)
          DropdownMenuItem(value: y, child: Text('$y')),
      ],
      onChanged: (v) => setState(() => _tahun = v),
    );
  }

  void _snack(String message, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }
}

class _Locked extends StatelessWidget {
  const _Locked({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'Simpan data auditor dulu',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Sertifikasi teknis bisa ditambahkan setelah data auditor tersimpan.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onBack, child: const Text('Kembali')),
        ],
      ),
    );
  }
}
