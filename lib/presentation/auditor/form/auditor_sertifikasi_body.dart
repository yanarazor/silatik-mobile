import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/url_opener.dart';
import '../../../data/models/auditor_model.dart';
import '../../../data/models/registrasi_model.dart';
import '../../../providers/auditor_form_provider.dart';
import '../../../providers/auditor_provider.dart';
import '../../shared/dokumen_upload_card.dart';
import 'auditor_profil_step.dart' show kAuditorFileMaxBytes;

class AuditorSertifikasiBody extends ConsumerStatefulWidget {
  const AuditorSertifikasiBody({
    super.key,
    required this.formKey,
    this.onAdded,
    this.showHeader = true,
  });

  final String? formKey;

  final VoidCallback? onAdded;

  final bool showHeader;

  @override
  ConsumerState<AuditorSertifikasiBody> createState() =>
      _AuditorSertifikasiBodyState();
}

class _AuditorSertifikasiBodyState
    extends ConsumerState<AuditorSertifikasiBody> {
  bool _deleting = false;

  String? get _auditorRef =>
      (widget.formKey != null && widget.formKey!.isNotEmpty)
          ? widget.formKey
          : null;

  void _refreshList() {
    final auditorRef = _auditorRef;
    if (auditorRef != null) {
      ref.invalidate(auditorSertifikasiProvider(auditorRef));
    }
  }

  Future<void> _openAddSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddSertifikatSheet(formKey: widget.formKey),
    );
    if (added == true) {
      _refreshList();
      widget.onAdded?.call();
    }
  }

  Future<void> _delete(AuditorCertificate cert) async {
    final auditorRef = _auditorRef;
    if (auditorRef == null || !cert.canDelete) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Sertifikat Teknis'),
        content: Text(
            'Apakah Anda yakin ingin menghapus sertifikat ${cert.nama}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _deleting = true);
    try {
      await ref.read(auditorRepoProvider).deleteSertifikasiTeknis(cert.ref);
      _refreshList();
      _snack('Sertifikat dihapus', error: false);
    } catch (e) {
      _snack('Gagal menghapus: $e');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auditorRef = _auditorRef;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
            children: [
              if (widget.showHeader) ...[
                Text(
                  'Sertifikasi Teknis',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacing16),
              if (auditorRef != null) _savedList(theme, auditorRef),
            ],
          ),
        ),
        // Tombol utama disematkan di bawah layar, membuka form (bottom sheet).
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: auditorRef == null ? null : _openAddSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Sertifikat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _savedList(ThemeData theme, String auditorRef) {
    final async = ref.watch(auditorSertifikasiProvider(auditorRef));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Row(
        children: [
          Expanded(
            child: Text('Gagal memuat daftar sertifikat',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.error)),
          ),
          TextButton(onPressed: _refreshList, child: const Text('Coba Lagi')),
        ],
      ),
      data: (certs) {
        if (certs.isEmpty) {
          return _EmptyState();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sertifikat Tersimpan (${certs.length})',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            for (final c in certs) _savedRow(theme, c),
          ],
        );
      },
    );
  }

  Widget _savedRow(ThemeData theme, AuditorCertificate cert) {
    final subtitle =
        [cert.lembaga, cert.tahun].where((e) => e.isNotEmpty).join(' • ');
    final hasUrl = cert.fileUrl.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12, vertical: AppTheme.spacing8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: const Color(0xFFECEFF3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_outlined,
              size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.nama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (hasUrl)
            IconButton(
              tooltip: 'Buka',
              visualDensity: VisualDensity.compact,
              onPressed: () => openFileUrl(context, cert.fileUrl),
              icon: const Icon(Icons.visibility_outlined,
                  size: 20, color: AppColors.primary),
            ),
          if (cert.canDelete)
            IconButton(
              tooltip: 'Hapus',
              visualDensity: VisualDensity.compact,
              onPressed: _deleting ? null : () => _delete(cert),
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.error),
            ),
        ],
      ),
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing24),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium_outlined,
              size: 40, color: AppColors.textSecondary),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Belum ada sertifikat',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'Tekan "Tambah Sertifikat" untuk menambahkan.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AddSertifikatSheet extends ConsumerStatefulWidget {
  const _AddSertifikatSheet({required this.formKey});

  final String? formKey;

  @override
  ConsumerState<_AddSertifikatSheet> createState() =>
      _AddSertifikatSheetState();
}

class _AddSertifikatSheetState extends ConsumerState<_AddSertifikatSheet> {
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
