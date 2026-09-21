import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/api_error_handler.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/url_opener.dart';
import '../../data/models/latik_profile.dart';
import '../../data/models/registrasi_model.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/latik_ext_provider.dart';
import '../../providers/profile_menu_provider.dart';
import '../auditor/form/auditor_profil_step.dart' show kAuditorFileMaxBytes;
import '../registration/widgets/step_indicator.dart';
import '../shared/dokumen_upload_card.dart';

const int _kLatikExtFee = 3750000;

class LatikPerpanjanganScreen extends ConsumerStatefulWidget {
  const LatikPerpanjanganScreen({super.key, required this.refExt});

  final String refExt;

  @override
  ConsumerState<LatikPerpanjanganScreen> createState() =>
      _LatikPerpanjanganScreenState();
}

class _LatikPerpanjanganScreenState
    extends ConsumerState<LatikPerpanjanganScreen> {
  int _step = 0;
  bool _loadStarted = false;

  String get _key => widget.refExt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (_loadStarted) return;
    _loadStarted = true;
    try {
      await ref.read(latikExtProvider(_key).notifier).load(widget.refExt);
    } catch (e) {
      if (mounted) _snack(ApiErrorHandler.messageFrom(e));
    }
  }

  Future<void> _pick(int id) async {
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
    ref.read(latikExtProvider(_key).notifier).setFile(
          id,
          FileItem(path: file.path ?? '', name: file.name, size: file.size),
        );
  }

  Future<void> _preview(FileItem doc) async {
    final path = doc.path.trim();
    if (path.toLowerCase().startsWith('http')) {
      await openFileUrl(context, path);
      return;
    }
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && mounted) {
      _snack('Gagal membuka berkas: ${result.message}');
    }
  }

  Future<void> _pickTanggal(int id, DateTime? current) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      ref.read(latikExtProvider(_key).notifier).setTanggal(id, picked);
    }
  }

  void _goData() => setState(() => _step = 0);
  void _goDokumen() => setState(() => _step = 1);

  void _goKonfirmasi() {
    final missing = ref.read(latikExtProvider(_key).notifier).missingRequired;
    if (missing.isNotEmpty) {
      _snack('Lengkapi dokumen wajib: ${missing.first}');
      return;
    }
    setState(() => _step = 2);
  }

  Future<void> _submit() async {
    try {
      final invoiceRef =
          await ref.read(latikExtProvider(_key).notifier).submit();
      if (!mounted) return;
      
      ref.invalidate(invoiceListProvider);
      _snack('Pengajuan perpanjangan berhasil dikirim', error: false);
      if (invoiceRef.isNotEmpty) {
        context.go(AppRoutes.transaksi);
      } else {
        context.pop();
      }
    } catch (e) {
      if (mounted) _snack(ApiErrorHandler.messageFrom(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(latikExtProvider(_key));
    const titles = ['Data LATIK', 'Dokumen Pendukung', 'Konfirmasi'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFE),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 22, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.primary),
                    onPressed: () {
                      if (_step > 0) {
                        setState(() => _step -= 1);
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perpanjangan LATIK',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${titles[_step]} • Langkah ${_step + 1} dari 3',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF5B6880),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: StepIndicator(current: _step, total: 3),
            ),
            const SizedBox(height: 18),
            Expanded(child: _buildStep(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(LatikExtState state) {
    switch (_step) {
      case 0:
        return _DataLatikStep(onNext: _goDokumen);
      case 1:
        return _DokumenStep(
          state: state,
          onPick: _pick,
          onPreview: _preview,
          onNomor: (id, v) =>
              ref.read(latikExtProvider(_key).notifier).setNomor(id, v),
          onTanggal: _pickTanggal,
          onBack: _goData,
          onNext: _goKonfirmasi,
        );
      default:
        return _KonfirmasiStep(
          submitting: state.submitting,
          onBack: _goDokumen,
          onSubmit: _submit,
        );
    }
  }

  void _snack(String message, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      );
  }
}

class _DokumenStep extends StatelessWidget {
  const _DokumenStep({
    required this.state,
    required this.onPick,
    required this.onPreview,
    required this.onNomor,
    required this.onTanggal,
    required this.onBack,
    required this.onNext,
  });

  final LatikExtState state;
  final void Function(int id) onPick;
  final void Function(FileItem doc) onPreview;
  final void Function(int id, String value) onNomor;
  final void Function(int id, DateTime? current) onTanggal;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.submitting && state.dokumen.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.dokumen.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            state.error != null
                ? 'Gagal memuat dokumen.\n${state.error}'
                : 'Belum ada dokumen persyaratan.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: ListView(
        children: [
          Text(
            'Dokumen Pendukung',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Unggah dokumen persyaratan perpanjangan (PDF, maks 10MB).',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacing16),
          for (final d in state.dokumen) ...[
            DokumenUploadCard(
              title: d.def.namaDokumen,
              requiredDoc: d.def.fileRequired,
              file: d.displayFile,
              onPick: () => onPick(d.def.id),
              onPreview: () {
                final f = d.displayFile;
                if (f != null) onPreview(f);
              },
              extraFields: (d.def.nomorRequired || d.def.tanggalRequired)
                  ? NomorTanggalFields(
                      showNomor: d.def.nomorRequired,
                      showTanggal: d.def.tanggalRequired,
                      nomor: d.nomor,
                      tanggal: d.tanggal,
                      onNomor: (v) => onNomor(d.def.id, v),
                      onTanggal: () => onTanggal(d.def.id, d.tanggal),
                    )
                  : null,
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
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
                  child: const Text('Lanjut'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DataLatikStep extends ConsumerWidget {
  const _DataLatikStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(latikProfileProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gagal memuat data lembaga.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(latikProfileProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
      data: (data) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        child: ListView(
          children: [
            Text(
              'Data Lembaga',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Periksa data lembaga sebelum melanjutkan. Perubahan data '
              'dilakukan melalui menu Profil Lembaga.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _InfoCard(data: data),
            const SizedBox(height: AppTheme.spacing24),
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
              ),
              child: const Text('Lanjut'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.data});

  final LatikProfile data;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Nama Lembaga', data.namaLatik),
      ('Nomor Registrasi', data.noPendaftaran),
      ('No. STR', data.noStr),
      ('NIB', data.noNib),
      ('NPWP', data.noNpwp),
      ('Email', data.email),
      ('Telepon', data.phone),
      ('Alamat', data.fullAddress),
      ('Website', data.website),
    ].where((e) => e.$2.trim().isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rows.isEmpty)
            Text(
              'Data lembaga belum tersedia.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 20, color: Color(0xFFF0F2F7)),
              _row(context, rows[i].$1, rows[i].$2),
            ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _KonfirmasiStep extends StatelessWidget {
  const _KonfirmasiStep({
    required this.submitting,
    required this.onBack,
    required this.onSubmit,
  });

  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rincian Biaya',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Biaya Perpanjangan LATIK',
                        style: theme.textTheme.bodyMedium),
                    Text(
                      AppFormatters.formatRupiah(_kLatikExtFee),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(
                      AppFormatters.formatRupiah(_kLatikExtFee),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            'Dengan menekan "Ajukan Perpanjangan", tagihan akan dibuat dan '
            'pengajuan dikirim untuk verifikasi. Kode tagihan dapat dilihat '
            'pada halaman Transaksi.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacing24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: submitting ? null : onBack,
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
                  onPressed: submitting ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium)),
                  ),
                  child: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Ajukan Perpanjangan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
