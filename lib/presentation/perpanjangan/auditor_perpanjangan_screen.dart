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
import '../../data/models/auditor_model.dart';
import '../../data/models/latik_ext_model.dart';
import '../../data/models/registrasi_model.dart';
import '../../providers/auditor_ext_provider.dart';
import '../../providers/auditor_provider.dart';
import '../../providers/invoice_provider.dart';
import '../auditor/form/auditor_profil_step.dart' show kAuditorFileMaxBytes;
import '../shared/step_indicator.dart';
import '../shared/auditor_check_tile.dart';
import '../shared/confirm_dialog.dart';
import '../shared/dokumen_upload_card.dart';

const int _kAuditorExtFee = 750000;

class AuditorPerpanjanganScreen extends ConsumerStatefulWidget {
  const AuditorPerpanjanganScreen({super.key, required this.refExt});

  final String refExt;

  @override
  ConsumerState<AuditorPerpanjanganScreen> createState() =>
      _AuditorPerpanjanganScreenState();
}

class _AuditorPerpanjanganScreenState
    extends ConsumerState<AuditorPerpanjanganScreen> {
  int _step = 0;

  final List<AuditorModel> _selected = [];

  String get _key => widget.refExt;

  void _toggle(AuditorModel a, bool? on) {
    setState(() {
      if (on == true) {
        if (!_selected.any((s) => s.id == a.id)) _selected.add(a);
      } else {
        _selected.removeWhere((s) => s.id == a.id);
      }
    });
  }

  Future<void> _continueFromSelect() async {
    if (_selected.isEmpty) {
      _snack('Pilih minimal satu auditor');
      return;
    }

    try {
      await ref
          .read(auditorExtProvider(_key).notifier)
          .selectAndLoad(widget.refExt, List.of(_selected));
    } catch (e) {
      if (mounted) _snack(ApiErrorHandler.messageFrom(e));
      return;
    }
    if (mounted) setState(() => _step = 1);
  }

  void _goKonfirmasi() {
    if (!ref.read(auditorExtProvider(_key).notifier).allComplete) {
      _snack('Lengkapi dokumen semua auditor terlebih dahulu');
      return;
    }
    setState(() => _step = 2);
  }

  Future<void> _openDocPage(int index) async {
    final auditor = _selected[index];
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AuditorDocPage(refExt: _key, auditorIndex: index, auditor: auditor),
      ),
    );

    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Ajukan Perpanjangan',
      message: 'Tagihan akan dibuat dan pengajuan dikirim untuk verifikasi. '
          'Lanjutkan?',
      confirmLabel: 'Ya, Ajukan',
    );
    if (!ok || !mounted) return;
    try {
      final invoiceRef =
          await ref.read(auditorExtProvider(_key).notifier).submit();
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
    final state = ref.watch(auditorExtProvider(_key));
    const titles = ['Pilih Auditor', 'Dokumen Pendukung', 'Konfirmasi'];

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
                          'Perpanjangan Auditor',
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

  Widget _buildStep(AuditorExtState state) {
    switch (_step) {
      case 0:
        return _SelectStep(
          selected: _selected,
          busy: state.submitting,
          onToggle: _toggle,
          onNext: _continueFromSelect,
        );
      case 1:
        return _DocHubStep(
          refExt: _key,
          selected: _selected,
          state: state,
          onOpen: _openDocPage,
          onRetry: _continueFromSelect,
          onNext: _goKonfirmasi,
        );
      default:
        return _KonfirmasiStep(
          count: _selected.length,
          submitting: state.submitting,
          onBack: () => setState(() => _step = 1),
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

/// Step 0 — pilih auditor. Checkbox hanya untuk yang `editableRenew`.
class _SelectStep extends ConsumerWidget {
  const _SelectStep({
    required this.selected,
    required this.busy,
    required this.onToggle,
    required this.onNext,
  });

  final List<AuditorModel> selected;

  final bool busy;
  final void Function(AuditorModel, bool?) onToggle;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(auditorListProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gagal memuat auditor'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(auditorListProvider),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
      data: (all) {
        final renewable = all.where((a) => a.editableRenew).toList();
        if (renewable.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 48,
                      color: AppColors.primary.withValues(alpha: 0.6)),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada auditor yang dapat diperpanjang saat ini.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Auditor',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Pilih auditor yang akan diperpanjang registrasinya.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacing16),
              Expanded(
                child: ListView.separated(
                  itemCount: renewable.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppTheme.spacing8),
                  itemBuilder: (_, i) {
                    final a = renewable[i];
                    final on = selected.any((s) => s.id == a.id);
                    return AuditorCheckTile(
                      auditor: a,
                      checked: on,
                      onChanged: (v) => onToggle(a, v),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              ElevatedButton(
                onPressed: (selected.isEmpty || busy) ? null : onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium)),
                ),
                child: busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Lanjut (${selected.length} dipilih)'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DocHubStep extends ConsumerWidget {
  const _DocHubStep({
    required this.refExt,
    required this.selected,
    required this.state,
    required this.onOpen,
    required this.onRetry,
    required this.onNext,
  });

  final String refExt;
  final List<AuditorModel> selected;
  final AuditorExtState state;
  final void Function(int index) onOpen;
  final VoidCallback onRetry;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.watch(auditorExtProvider(refExt).notifier);

    if (state.submitting && state.flatDocs.isEmpty && state.docError == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.docError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                state.docError!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    final allComplete = notifier.allComplete;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dokumen per Auditor',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Lengkapi dokumen untuk setiap auditor terpilih.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Expanded(
            child: ListView.separated(
              itemCount: selected.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTheme.spacing8),
              itemBuilder: (_, i) {
                final complete = notifier.isAuditorComplete(i);
                return _AuditorDocRow(
                  nama: selected[i].nama,
                  complete: complete,
                  onTap: () => onOpen(i),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          ElevatedButton(
            onPressed: allComplete ? onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
            ),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
  }
}

class _AuditorDocRow extends StatelessWidget {
  const _AuditorDocRow({
    required this.nama,
    required this.complete,
    required this.onTap,
  });

  final String nama;
  final bool complete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Icon(
                complete ? Icons.check_circle_rounded : Icons.pending_outlined,
                color: complete ? AppColors.success : AppColors.textSecondary,
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama.isEmpty ? 'Auditor' : nama,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      complete ? 'Dokumen lengkap' : 'Belum lengkap',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: complete
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditorDocPage extends ConsumerWidget {
  const _AuditorDocPage({
    required this.refExt,
    required this.auditorIndex,
    required this.auditor,
  });

  final String refExt;
  final int auditorIndex;
  final AuditorModel auditor;

  Future<void> _pick(BuildContext context, WidgetRef ref, int docId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;
    final file = result.files.single;
    if (file.size > kAuditorFileMaxBytes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ukuran file maksimal 10MB')),
        );
      }
      return;
    }
    ref.read(auditorExtProvider(refExt).notifier).setFile(
          docId,
          FileItem(path: file.path ?? '', name: file.name, size: file.size),
        );
  }

  Future<void> _preview(BuildContext context, FileItem doc) async {
    final path = doc.path.trim();
    if (path.toLowerCase().startsWith('http')) {
      await openFileUrl(context, path);
      return;
    }
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka berkas: ${result.message}')),
      );
    }
  }

  Future<void> _pickTanggal(
      BuildContext context, WidgetRef ref, int docId, DateTime? current) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      ref.read(auditorExtProvider(refExt).notifier).setTanggal(docId, picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(auditorExtProvider(refExt));
    final notifier = ref.read(auditorExtProvider(refExt).notifier);
    final docs = notifier.docsForAuditor(auditorIndex);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFE),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          auditor.nama.isEmpty ? 'Dokumen Auditor' : auditor.nama,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
          child: ListView(
            children: [
              Text(
                'Unggah dokumen persyaratan (PDF, maks 10MB).',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacing16),
              for (final d in docs) ...[
                _docCard(context, ref, state, d),
                const SizedBox(height: AppTheme.spacing16),
              ],
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium)),
                ),
                child: const Text('Selesai'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _docCard(
    BuildContext context,
    WidgetRef ref,
    AuditorExtState state,
    ExtDokumen d,
  ) {
    final draft = state.drafts[d.id];
    return DokumenUploadCard(
      title: d.namaDokumen,
      requiredDoc: d.fileRequired,
      file: draft?.displayFile,
      onPick: () => _pick(context, ref, d.id),
      onPreview: () {
        final f = draft?.displayFile;
        if (f != null) _preview(context, f);
      },
      extraFields: (d.nomorRequired || d.tanggalRequired)
          ? NomorTanggalFields(
              showNomor: d.nomorRequired,
              showTanggal: d.tanggalRequired,
              nomor: draft?.nomor ?? '',
              tanggal: draft?.tanggal,
              onNomor: (v) =>
                  ref.read(auditorExtProvider(refExt).notifier).setNomor(d.id, v),
              onTanggal: () =>
                  _pickTanggal(context, ref, d.id, draft?.tanggal),
            )
          : null,
    );
  }
}

class _KonfirmasiStep extends StatelessWidget {
  const _KonfirmasiStep({
    required this.count,
    required this.submitting,
    required this.onBack,
    required this.onSubmit,
  });

  final int count;
  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _kAuditorExtFee * count;
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
                    Text('Biaya per Auditor', style: theme.textTheme.bodyMedium),
                    Text(
                      AppFormatters.formatRupiah(_kAuditorExtFee),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Jumlah Auditor', style: theme.textTheme.bodyMedium),
                    Text('$count',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
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
                      AppFormatters.formatRupiah(total),
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
