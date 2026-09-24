import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/api_error_handler.dart';
import '../../core/utils/api_response_utils.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/url_opener.dart';
import '../../data/models/auditor_model.dart';
import '../../data/models/latik_profile.dart';
import '../../data/models/profil_dokumen.dart';
import '../../data/models/registrasi_model.dart';
import '../../data/services/auditor_ext_payload.dart';
import '../../data/services/latik_service.dart';
import '../../providers/auditor_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/latik_verifikasi_provider.dart';
import '../../providers/profile_menu_provider.dart';
import '../auditor/form/auditor_profil_step.dart' show kAuditorFileMaxBytes;
import '../shared/step_indicator.dart';
import '../shared/auditor_check_tile.dart';
import '../shared/confirm_dialog.dart';
import '../shared/dokumen_upload_card.dart';
import '../shared/latik_info_section.dart';
import '../shared/pks_notice.dart';

class LatikVerifikasiScreen extends ConsumerStatefulWidget {
  const LatikVerifikasiScreen({super.key, required this.profile});

  final LatikProfile profile;

  @override
  ConsumerState<LatikVerifikasiScreen> createState() =>
      _LatikVerifikasiScreenState();
}

class _DocEdit {
  FileItem? file;
  bool newlyPicked;
  final TextEditingController nomor;
  DateTime? tanggal;

  _DocEdit({this.file, String nomor = '', this.tanggal})
      : newlyPicked = false,
        nomor = TextEditingController(text: nomor);
}

class _LatikVerifikasiScreenState
    extends ConsumerState<LatikVerifikasiScreen> {
  int _step = 0;

  final Map<int, _DocEdit> _edits = {};
  List<ProfilDokumen> _docs = const [];
  bool _docsInitialized = false;

  String get _latikRef => widget.profile.latikRef;
  String get _status => widget.profile.statusVerifikasi;

  @override
  void dispose() {
    for (final e in _edits.values) {
      e.nomor.dispose();
    }
    super.dispose();
  }

  void _initEdits(List<ProfilDokumen> docs) {
    _docs = docs;
    _edits.clear();
    for (final d in docs) {
      if (d.id == null) continue;
      _edits[d.id!] = _DocEdit(
        file: d.url.trim().isEmpty
            ? null
            : FileItem(path: d.url, name: _fileNameFromUrl(d.url), size: 0),
        nomor: d.nomor,
        tanggal: parseFlexibleDate(d.tanggal),
      );
    }
    _docsInitialized = true;
  }

  // -------------------------------------------------------------- navigation

  void _next() => setState(() => _step += 1);
  void _back() {
    if (_step > 0) {
      setState(() => _step -= 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _fromDokumen() {
    if (_buildUploads() == null) return;
    _next();
  }

  void _fromAuditor() {
    final s = ref.read(latikVerifikasiProvider(_latikRef));
    if (!s.hasSelection) {
      _snack('Pilih minimal satu auditor');
      return;
    }
    if (!s.hasTetap) {
      _snack('Pilih minimal satu auditor Tetap');
      return;
    }
    _next();
  }

  Future<void> _submit() async {
    final uploads = _buildUploads();
    if (uploads == null) {
      setState(() => _step = 1); // kembali ke langkah dokumen bila tak valid
      return;
    }
    final isResubmit = _status == kStatusRejected;
    final ok = await showConfirmDialog(
      context,
      title: 'Ajukan Verifikasi',
      message: isResubmit
          ? 'Pengajuan akan dikirim ulang untuk verifikasi tanpa membuat '
              'tagihan baru. Lanjutkan?'
          : 'Tagihan akan dibuat dan pengajuan dikirim untuk verifikasi. '
              'Lanjutkan?',
      confirmLabel: 'Ya, Ajukan',
    );
    if (!ok || !mounted) return;
    try {
      final invoiceRef = await ref
          .read(latikVerifikasiProvider(_latikRef).notifier)
          .submit(status: _status, uploads: uploads);
      if (!mounted) return;
      ref.invalidate(invoiceListProvider);
      _snack('Pengajuan verifikasi berhasil dikirim', error: false);
      if (invoiceRef.isNotEmpty) {
        context.go(AppRoutes.transaksi);
      } else {
        context.pop();
      }
    } catch (e) {
      if (mounted) _snack(ApiErrorHandler.messageFrom(e));
    }
  }

  // --------------------------------------------------------------- dokumen io

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
    setState(() {
      _edits[id]
        ?..file =
            FileItem(path: file.path ?? '', name: file.name, size: file.size)
        ..newlyPicked = true;
    });
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

  Future<void> _pickDate(int id, DateTime? current) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
      initialDate: current ?? DateTime.now(),
    );
    if (date != null) setState(() => _edits[id]?.tanggal = date);
  }

  List<DokumenUpload>? _buildUploads() {
    final uploads = <DokumenUpload>[];
    for (final d in _docs) {
      final id = d.id;
      if (id == null) continue;
      final e = _edits[id]!;
      final hasFile = e.file != null;

      if (d.fileRequired && !hasFile) {
        _snack('Dokumen wajib belum lengkap: ${d.nama}');
        return null;
      }
      if (hasFile && d.nomorRequired && e.nomor.text.trim().isEmpty) {
        _snack('Nomor wajib diisi: ${d.nama}');
        return null;
      }
      if (hasFile && d.tanggalRequired && e.tanggal == null) {
        _snack('Tanggal wajib diisi: ${d.nama}');
        return null;
      }

      uploads.add(DokumenUpload(
        id: id,
        file: e.newlyPicked && e.file != null ? File(e.file!.path) : null,
        fileName: e.newlyPicked ? e.file?.name : null,
        nomor: e.nomor.text.trim(),
        tanggal: e.tanggal == null ? null : _formatDate(e.tanggal!),
      ));
    }
    return uploads;
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(latikVerifikasiProvider(_latikRef));
    const titles = [
      'Data LATIK',
      'Dokumen Pendukung',
      'Auditor',
      'Konfirmasi',
    ];

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
                    onPressed: state.submitting ? null : _back,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ajukan Verifikasi',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${titles[_step]} • Langkah ${_step + 1} dari 4',
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
              child: StepIndicator(current: _step, total: 4),
            ),
            const SizedBox(height: 18),
            Expanded(child: _buildStep(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(LatikVerifikasiState state) {
    switch (_step) {
      case 0:
        return _DataStep(profile: widget.profile, onNext: _next);
      case 1:
        return _DokumenStep(
          docsAsync: ref.watch(dokumenBerkasProvider),
          ensureInit: (docs) {
            if (!_docsInitialized) _initEdits(docs);
          },
          edits: _edits,
          onPick: _pick,
          onPreview: _preview,
          onPickDate: _pickDate,
          onRetry: () => ref.invalidate(dokumenBerkasProvider),
          onBack: _back,
          onNext: _fromDokumen,
        );
      case 2:
        return _AuditorStep(
          latikRef: _latikRef,
          auditorsAsync: ref.watch(auditorListProvider),
          onRetry: () => ref.invalidate(auditorListProvider),
          onBack: _back,
          onNext: _fromAuditor,
        );
      default:
        return _KonfirmasiStep(
          auditors: state.selected,
          submitting: state.submitting,
          editable: widget.profile.editable,
          isResubmit: _status == kStatusRejected,
          onBack: _back,
          onSubmit: _submit,
        );
    }
  }

  // ------------------------------------------------------------------ helpers

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

  static String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd-$mm-${d.year}';
  }

  static String _fileNameFromUrl(String url) {
    final clean = url.split('?').first;
    final seg = clean.split('/').where((s) => s.isNotEmpty).toList();
    return seg.isEmpty ? 'dokumen' : Uri.decodeComponent(seg.last);
  }
}

// ============================================================ Step 1: Data
class _DataStep extends StatelessWidget {
  const _DataStep({required this.profile, required this.onNext});

  final LatikProfile profile;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
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
          LatikInfoSection(data: profile),
          if (LatikLocationCard.maybeBuild(profile) case final map?) ...[
            const SizedBox(height: AppTheme.spacing16),
            map,
          ],
          const SizedBox(height: AppTheme.spacing24),
          ElevatedButton(
            onPressed: onNext,
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

// ========================================================= Step 2: Dokumen

class _DokumenStep extends StatelessWidget {
  const _DokumenStep({
    required this.docsAsync,
    required this.ensureInit,
    required this.edits,
    required this.onPick,
    required this.onPreview,
    required this.onPickDate,
    required this.onRetry,
    required this.onBack,
    required this.onNext,
  });

  final AsyncValue<List<ProfilDokumen>> docsAsync;
  final void Function(List<ProfilDokumen>) ensureInit;
  final Map<int, _DocEdit> edits;
  final void Function(int) onPick;
  final void Function(FileItem) onPreview;
  final void Function(int, DateTime?) onPickDate;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return docsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gagal memuat dokumen'),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
      data: (loaded) {
        ensureInit(loaded);
        final shown = loaded.where((d) => d.id != null).toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: shown.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppTheme.spacing16),
                  itemBuilder: (_, i) => _docGroup(context, shown[i]),
                ),
              ),
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
                      child: const Text('Selanjutnya'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _docGroup(BuildContext context, ProfilDokumen d) {
    final e = edits[d.id]!;
    final hasExtra = d.nomorRequired || d.tanggalRequired;
    return DokumenUploadCard(
      title: d.nama.isEmpty ? 'Dokumen' : d.nama,
      requiredDoc: d.fileRequired,
      file: e.file,
      onPick: () => onPick(d.id!),
      onPreview: () {
        final f = e.file;
        if (f != null) onPreview(f);
      },
      extraFields: hasExtra
          ? NomorTanggalFields(
              showNomor: d.nomorRequired,
              showTanggal: d.tanggalRequired,
              nomor: e.nomor.text,
              tanggal: e.tanggal,
              onNomor: (v) => e.nomor.text = v,
              onTanggal: () => onPickDate(d.id!, e.tanggal),
            )
          : null,
    );
  }
}

// ========================================================= Step 3: Auditor

class _AuditorStep extends ConsumerWidget {
  const _AuditorStep({
    required this.latikRef,
    required this.auditorsAsync,
    required this.onRetry,
    required this.onBack,
    required this.onNext,
  });

  final String latikRef;
  final AsyncValue<List<AuditorModel>> auditorsAsync;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(latikVerifikasiProvider(latikRef).notifier);
    // watch supaya checkbox rerender saat seleksi berubah.
    ref.watch(latikVerifikasiProvider(latikRef));

    return auditorsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gagal memuat auditor'),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
      data: (all) {
        if (all.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada auditor. Tambahkan auditor terlebih dahulu.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: all.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final a = all[i];
                    return AuditorCheckTile(
                      auditor: a,
                      checked: notifier.isSelected(a),
                      onChanged: (on) => notifier.toggle(a, on ?? false),
                    );
                  },
                ),
              ),
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
                      child: const Text('Selanjutnya'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ======================================================= Step 4: Konfirmasi

class _KonfirmasiStep extends StatelessWidget {
  const _KonfirmasiStep({
    required this.auditors,
    required this.submitting,
    required this.editable,
    required this.isResubmit,
    required this.onBack,
    required this.onSubmit,
  });

  final List<AuditorModel> auditors;
  final bool submitting;
  final bool editable;
  final bool isResubmit;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      for (final a in auditors)
        LatikRegAuditorItem(ref: a.id, nama: a.nama, status: a.status),
    ];
    const base = 5000000;
    final total = latikRegistrationTotal(items);
    final firstTetapIdx = items.indexWhere((a) => a.isTetap);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: ListView(
        children: [
          const PksNotice(),
          const SizedBox(height: AppTheme.spacing16),
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
                _row(theme, 'Registrasi LATIK',
                    AppFormatters.formatRupiah(base)),
                const SizedBox(height: 8),
                if (firstTetapIdx != -1) ...[
                  _row(
                    theme,
                    'Auditor: ${items[firstTetapIdx].nama} (Tetap)',
                    'Gratis',
                  ),
                  const SizedBox(height: 8),
                ],
                for (var i = 0; i < items.length; i++) ...[
                  if (i != firstTetapIdx) ...[
                    _row(
                      theme,
                      'Auditor: ${items[i].nama}'
                          '${items[i].isTetap ? " (Tetap)" : ""}',
                      AppFormatters.formatRupiah(1000000),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
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
            isResubmit
                ? 'Pengajuan sebelumnya dikembalikan. Menekan "Ajukan '
                    'Verifikasi" akan mengirim ulang untuk diverifikasi tanpa '
                    'membuat tagihan baru. Rincian di atas hanya ringkasan '
                    'biaya registrasi awal.'
                : 'Dengan menekan "Ajukan Verifikasi", tagihan akan dibuat dan '
                    'pengajuan dikirim untuk verifikasi. Kode tagihan dapat '
                    'dilihat pada halaman Transaksi.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          if (!editable) ...[
            const SizedBox(height: AppTheme.spacing12),
            Text(
              'Data LATIK sedang tidak dapat diajukan (read-only).',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: AppTheme.spacing24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: submitting ? null : onBack,
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
                  onPressed: (submitting || !editable) ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.textSecondary.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing12),
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
                      : const Text('Ajukan Verifikasi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      );
}
