import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/url_opener.dart';
import '../../../../data/models/registrasi_model.dart';
import '../../../../providers/auditor_form_provider.dart';
import '../../../shared/dokumen_upload_card.dart';
import '../auditor_profil_step.dart' show kAuditorFileMaxBytes;

/// Isi bottom sheet form tambah sertifikat. Pop dengan `true` saat sukses.
class AddSertifikatSheet extends ConsumerStatefulWidget {
  const AddSertifikatSheet({super.key, required this.formKey});

  final String? formKey;

  @override
  ConsumerState<AddSertifikatSheet> createState() => _AddSertifikatSheetState();
}

class _AddSertifikatSheetState extends ConsumerState<AddSertifikatSheet> {
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

  Future<void> _preview() async {
    final doc = _file;
    if (doc == null) return;
    final path = doc.path.trim();
    if (path.toLowerCase().startsWith('http')) {
      await openFileUrl(context, path);
      return;
    }
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      _snack('Gagal membuka berkas: ${result.message}');
    }
  }

  Future<void> _save() async {
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
      await ref
          .read(auditorFormProvider(widget.formKey).notifier)
          .addSertifikat(
            namaPelatihan: _form.control('nama_pelatihan').value ?? '',
            tahun: _tahun.toString(),
            lembaga: _form.control('lembaga').value ?? '',
            sertifikatFile: _file!,
            auditorRef: widget.formKey,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _snack('Gagal menambah sertifikat: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final submitting = ref.watch(auditorFormProvider(widget.formKey)).submitting;
    // Sisakan ruang untuk keyboard saat mengetik.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(22, 16, 22, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E4EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Tambah Sertifikat',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
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
                  DokumenUploadCard(
                    title: 'Sertifikat (PDF)',
                    requiredDoc: true,
                    file: _file,
                    onPick: _pickFile,
                    onPreview: _preview,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            ElevatedButton.icon(
              onPressed: submitting ? null : _save,
              icon: submitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, size: 18),
              label: const Text('Simpan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
              ),
            ),
          ],
        ),
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