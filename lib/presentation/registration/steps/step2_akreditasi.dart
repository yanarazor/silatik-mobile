import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/file_utils.dart';
import '../../../data/models/registrasi_model.dart';
import '../../../providers/registrasi_provider.dart';

class Step2Akreditasi extends ConsumerStatefulWidget {
  const Step2Akreditasi({super.key});

  @override
  ConsumerState<Step2Akreditasi> createState() => _Step2AkreditasiState();
}

class _Step2AkreditasiState extends ConsumerState<Step2Akreditasi> {
  final form = FormGroup({
    'nomor': FormControl<String>(validators: [Validators.required])
  });
  DateTime? terbit;
  DateTime? berakhir;
  final scopes = <String>{};
  FileItem? selected;
  bool _prefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    final data = ref.read(registrasiProvider).data;
    form.control('nomor').value = data.nomorKan;
    terbit = data.terbitKan;
    berakhir = data.berakhirKan;
    scopes.addAll(data.ruangLingkup);
    selected = data.sertifikatKan;
    _prefilled = true;
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
    if (result == null) return;
    final file = result.files.single;
    if (file.size > FileUtils.maxSizeBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ukuran file maksimal 5MB')));
      return;
    }
    setState(() => selected =
        FileItem(path: file.path ?? '', name: file.name, size: file.size));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: ReactiveForm(
            formGroup: form,
            child: ListView(
              children: [
                Text(
                  'Data Akreditasi KAN',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                ReactiveTextField(
                  formControlName: 'nomor',
                  decoration: InputDecoration(
                    labelText: 'Nomor Sertifikat Akreditasi KAN*',
                    prefixIcon:
                        const Icon(Icons.article, color: AppColors.primary),
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: const BorderSide(
                          color: AppColors.textSecondary, width: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                _buildDatePicker(
                  context,
                  title: 'Tanggal Terbit Akreditasi*',
                  date: terbit,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDate: DateTime.now(),
                    );
                    if (date != null) setState(() => terbit = date);
                  },
                ),
                const SizedBox(height: AppTheme.spacing8),
                _buildDatePicker(
                  context,
                  title: 'Tanggal Berakhir Akreditasi*',
                  date: berakhir,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDate: DateTime.now(),
                    );
                    if (date != null) setState(() => berakhir = date);
                  },
                ),
                const SizedBox(height: AppTheme.spacing12),
                Text(
                  'Ruang Lingkup Akreditasi*',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Wrap(
                  spacing: AppTheme.spacing8,
                  runSpacing: AppTheme.spacing8,
                  children: [
                    'Audit Aplikasi SPBE',
                    'Audit Infrastruktur SPBE',
                    'Audit Organisasi SPBE'
                  ]
                      .map(
                        (e) => FilterChip(
                          label: Text(e),
                          selected: scopes.contains(e),
                          onSelected: (v) => setState(
                              () => v ? scopes.add(e) : scopes.remove(e)),
                          backgroundColor: scopes.contains(e)
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          labelStyle: TextStyle(
                            color: scopes.contains(e)
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: scopes.contains(e)
                                ? AppColors.primary
                                : AppColors.textSecondary.withValues(alpha: 0.3),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppTheme.spacing12),
                OutlinedButton.icon(
                  onPressed: pickFile,
                  icon:
                      const Icon(Icons.cloud_upload, color: AppColors.primary),
                  label: const Text('Upload Sertifikat Akreditasi KAN*'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing12,
                        horizontal: AppTheme.spacing16),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium)),
                  ),
                ),
                if (selected != null)
                  Container(
                    margin: const EdgeInsets.only(top: AppTheme.spacing12),
                    padding: const EdgeInsets.all(AppTheme.spacing12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      border:
                          Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.description,
                          color: AppColors.primary),
                      title: Text(
                        selected!.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        FileUtils.formatBytes(selected!.size),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isWebUrl(selected!.path))
                            IconButton(
                              onPressed: () => _openUrl(selected!.path),
                              icon: const Icon(Icons.open_in_new,
                                  color: AppColors.primary),
                            ),
                          IconButton(
                            onPressed: () => setState(() => selected = null),
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppTheme.spacing16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            ref.read(registrasiProvider.notifier).setStep(0),
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
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (form.invalid ||
                              terbit == null ||
                              berakhir == null ||
                              scopes.isEmpty ||
                              selected == null) {
                            _showErrorSnackBar(
                                'Lengkapi semua data akreditasi');
                            return;
                          }
                          ref.read(registrasiProvider.notifier).setAkreditasi(
                                nomor: form.control('nomor').value,
                                terbit: terbit!,
                                berakhir: berakhir!,
                                ruangLingkup: scopes.toList(),
                                file: selected!,
                              );
                          ref.read(registrasiProvider.notifier).setStep(2);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacing12),
                          backgroundColor: AppColors.primary,
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
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool _isWebUrl(String value) {
    final text = value.trim().toLowerCase();
    return text.startsWith('http://') || text.startsWith('https://');
  }

  Future<void> _openUrl(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      _showErrorSnackBar('URL sertifikat tidak valid');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      _showErrorSnackBar('Gagal membuka sertifikat');
    }
  }

  Widget _buildDatePicker(BuildContext context,
      {required String title, DateTime? date, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing12, vertical: AppTheme.spacing12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  date == null
                      ? 'Pilih tanggal'
                      : date.toString().split(' ').first,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: date == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Icon(Icons.calendar_today, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
