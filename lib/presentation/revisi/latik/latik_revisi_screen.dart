import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/api_error_handler.dart';
import '../../../core/utils/url_opener.dart';
import '../../../data/models/registrasi_model.dart';
import '../../../providers/latik_revisi_provider.dart';
import '../../auditor/form/auditor_profil_step.dart' show kAuditorFileMaxBytes;
import '../../shared/confirm_dialog.dart';
import '../../shared/step_indicator.dart';
import '../../shared/wizard_header.dart';
import '../../perpanjangan/latik/steps/data_latik_step.dart';
import '../widgets/revisi_state_views.dart';
import 'steps/latik_revisi_doc_step.dart';

/// Live LATIK revision flow. Revision list, documents and actions are backed
/// by the LATIK revision provider; auditor revision flows remain in mock stage.
class LatikRevisiScreen extends ConsumerStatefulWidget {
  const LatikRevisiScreen({super.key});

  @override
  ConsumerState<LatikRevisiScreen> createState() => _LatikRevisiScreenState();
}

class _LatikRevisiScreenState extends ConsumerState<LatikRevisiScreen> {
  int _step = 0;
  bool _loadStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (_loadStarted) return;
    _loadStarted = true;
    try {
      await ref.read(latikRevisiProvider.notifier).load();
    } catch (e) {
      if (mounted) _snack(ApiErrorHandler.messageFrom(e), error: true);
    }
  }

  Future<void> _pickFile(int id) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;
    final file = result.files.single;
    if (file.size > kAuditorFileMaxBytes) {
      _snack('Ukuran file maksimal 10MB', error: true);
      return;
    }
    ref.read(latikRevisiProvider.notifier).setFile(
          id,
          FileItem(path: file.path ?? '', name: file.name, size: file.size),
        );
    _snack('Berkas ${file.name} dipilih. Tekan Simpan untuk menyimpan.');
  }

  Future<void> _previewFile(FileItem file) async {
    final path = file.path.trim();
    if (path.toLowerCase().startsWith('http')) {
      await openFileUrl(context, path);
      return;
    }
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && mounted) {
      _snack('Gagal membuka berkas: ${result.message}', error: true);
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
      ref.read(latikRevisiProvider.notifier).setTanggal(id, picked);
    }
  }

  Future<void> _save() async {
    final notifier = ref.read(latikRevisiProvider.notifier);
    final missing = notifier.missingRequired;
    if (missing.isNotEmpty) {
      _snack('Lengkapi dokumen wajib: ${missing.first}', error: true);
      return;
    }
    try {
      await notifier.saveDokumen();
      if (mounted) _snack('Dokumen berhasil diupload');
    } catch (e) {
      if (mounted) _snack(ApiErrorHandler.messageFrom(e), error: true);
    }
  }

  Future<void> _submit(LatikRevisiState state) async {
    if (state.hasUnsavedEdits) {
      _snack(
        'Ada perubahan yang belum disimpan. Simpan dokumen sebelum mengajukan.',
        error: true,
      );
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: 'Ajukan Revisi LATIK',
      message:
          'Pastikan dokumen telah diperbaiki sesuai catatan verifikator. Ajukan kembali untuk verifikasi?',
      confirmLabel: 'Ya, Ajukan Revisi',
    );
    if (!ok || !mounted) return;

    try {
      await ref.read(latikRevisiProvider.notifier).submitRevisi();
      if (!mounted) return;
      _snack('Berhasil mengirim permintaan verifikasi');
      context.go(AppRoutes.dashboard);
    } catch (e) {
      if (mounted) _snack(ApiErrorHandler.messageFrom(e), error: true);
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.error : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(latikRevisiProvider);
    const steps = ['Data Lembaga', 'Dokumen Pendukung'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFE),
      body: SafeArea(
        child: Column(
          children: [
            WizardHeader(
              title: 'Revisi Perpanjangan LATIK',
              subtitle: '${steps[_step]} • Langkah ${_step + 1} dari 2',
              onBack: state.isBusy
                  ? null
                  : () => _step > 0
                      ? setState(() => _step--)
                      : Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: StepIndicator(current: _step, total: 2),
            ),
            const SizedBox(height: 12),
            Expanded(child: _body(state)),
          ],
        ),
      ),
    );
  }

  Widget _body(LatikRevisiState state) {
    if (state.isLoading || state.status == LatikRevisiStatus.idle) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Memuat data revisi LATIK...'),
          ],
        ),
      );
    }
    if (state.status == LatikRevisiStatus.error) {
      return RevisiStateViews(
        loadingText: '',
        emptyTitle: '',
        emptyMessage: '',
        errorTitle: 'Gagal Memuat Data',
        errorMessage: state.errorMessage == null
            ? 'Terjadi kesalahan mengambil data.'
            : ApiErrorHandler.messageFrom(state.errorMessage!),
        onRetry: () {
          _loadStarted = false;
          setState(() {});
          _load();
        },
      ).error();
    }
    if (state.refExt.isEmpty) {
      return RevisiStateViews(
        loadingText: '',
        emptyTitle: 'Tidak ada permohonan yang dikembalikan',
        emptyMessage:
            'Saat ini tidak ada pengajuan perpanjangan LATIK yang memerlukan revisi.',
        emptyButtonLabel: 'Kembali',
        errorTitle: '',
        errorMessage: '',
        onRetry: () => Navigator.of(context).pop(),
      ).empty();
    }
    if (_step == 0) {
      return DataLatikStep(onNext: () => setState(() => _step = 1));
    }
    return LatikRevisiDocStep(
      docs: state.dokumen,
      hasUnsavedEdits: state.hasUnsavedEdits,
      isSaving: state.isSaving,
      isSubmitting: state.isSubmitting,
      onPickFile: _pickFile,
      onPreviewFile: _previewFile,
      onNomorChanged: ref.read(latikRevisiProvider.notifier).setNomor,
      onTanggalPicked: _pickTanggal,
      onSave: _save,
      onSubmit: () => _submit(state),
    );
  }
}
