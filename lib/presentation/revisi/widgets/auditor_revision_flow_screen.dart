import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/api_error_handler.dart';
import '../../../core/utils/url_opener.dart';
import '../../../data/models/latik_ext_model.dart';
import '../../../data/models/registrasi_model.dart';
import '../../../providers/auditor_add_revisi_provider.dart';
import '../../../providers/auditor_revisi_engine.dart';
import '../../../providers/auditor_revisi_provider.dart';
import '../../auditor/form/auditor_profil_step.dart' show kAuditorFileMaxBytes;
import '../../shared/confirm_dialog.dart';
import '../../shared/step_indicator.dart';
import '../../shared/wizard_header.dart';
import 'auditor_revision_docs_step.dart';
import 'auditor_revision_select_step.dart';
import 'revisi_state_views.dart';

/// Live wizard engine for both Flow 2 (Auditor Renewal) and Flow 3 (Add Auditor).
class AuditorRevisionFlowScreen extends ConsumerStatefulWidget {
  const AuditorRevisionFlowScreen({
    super.key,
    required this.title,
    required this.submitTitle,
    required this.successMessage,
    required this.emptyMessage,
    required this.isAddAuditor,
  });

  final String title;
  final String submitTitle;
  final String successMessage;
  final String emptyMessage;
  final bool isAddAuditor;

  @override
  ConsumerState<AuditorRevisionFlowScreen> createState() =>
      _AuditorRevisionFlowScreenState();
}

class _AuditorRevisionFlowScreenState
    extends ConsumerState<AuditorRevisionFlowScreen> {
  int _step = 0;
  bool _loadStarted = false;

  AutoDisposeStateNotifierProvider<AuditorRevisiNotifier, AuditorRevisiState>
      get _provider => widget.isAddAuditor
          ? auditorAddRevisiProvider
          : auditorRevisiProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (_loadStarted) return;
    _loadStarted = true;
    try {
      await ref.read(_provider.notifier).load();
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

  Future<void> _pickFile(int docId) async {
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
    ref.read(_provider.notifier).setFile(
          docId,
          FileItem(path: file.path ?? '', name: file.name, size: file.size),
        );
    _snack('Berkas ${file.name} dipilih.');
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

  Future<void> _pickTanggal(int docId, DateTime? current) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      ref.read(_provider.notifier).setTanggal(docId, picked);
    }
  }

  Future<void> _save() async {
    final notifier = ref.read(_provider.notifier);
    final missing = notifier.missingRequired;
    if (missing.isNotEmpty) {
      _snack('Lengkapi dokumen wajib: ${missing.first}', error: true);
      return;
    }
    try {
      await notifier.saveDokumen();
      if (mounted) _snack('Draft revisi dokumen auditor berhasil disimpan!');
    } catch (e) {
      if (mounted) _snack(ApiErrorHandler.messageFrom(e), error: true);
    }
  }

  Future<void> _submit(AuditorRevisiState state) async {
    if (state.hasUnsavedEdits) {
      _snack(
        'Terdapat perubahan dokumen yang belum disimpan. Silakan tekan Simpan terlebih dahulu.',
        error: true,
      );
      return;
    }
    final count = state.selectedIds.length;
    final ok = await showConfirmDialog(
      context,
      title: widget.submitTitle,
      message:
          'Pastikan berkas $count auditor terpilih sudah sesuai. Lanjutkan pengajuan?',
      confirmLabel: 'Ya, Ajukan Revisi',
    );
    if (!ok || !mounted) return;

    try {
      await ref.read(_provider.notifier).submit();
      if (!mounted) return;
      _snack(widget.successMessage);
      context.go(AppRoutes.dashboard);
    } catch (e) {
      if (mounted) _snack(ApiErrorHandler.messageFrom(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);
    const steps = ['Pilih Auditor', 'Dokumen Auditor'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFE),
      body: SafeArea(
        child: Column(
          children: [
            WizardHeader(
              title: widget.title,
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

  Widget _body(AuditorRevisiState state) {
    if (state.isLoading || state.status == AuditorRevisiStatus.idle) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Memuat data revisi auditor...'),
          ],
        ),
      );
    }
    if (state.status == AuditorRevisiStatus.error) {
      return RevisiStateViews(
        loadingText: '',
        emptyTitle: '',
        emptyMessage: '',
        errorTitle: 'Gagal Memuat Data Auditor',
        errorMessage: state.errorMessage == null
            ? 'Terjadi kendala saat mengambil data.'
            : ApiErrorHandler.messageFrom(state.errorMessage!),
        onRetry: () {
          _loadStarted = false;
          setState(() {});
          _load();
        },
      ).error();
    }
    if (state.allAuditors.isEmpty) {
      return RevisiStateViews(
        loadingText: '',
        emptyTitle: 'Tidak Ada Auditor Perlu Revisi',
        emptyMessage: widget.emptyMessage,
        emptyButtonLabel: 'Kembali',
        errorTitle: '',
        errorMessage: '',
        onRetry: () => Navigator.of(context).pop(),
      ).empty();
    }
    if (state.docError != null) {
      return RevisiStateViews(
        loadingText: '',
        emptyTitle: '',
        emptyMessage: '',
        errorTitle: 'Kesalahan Dokumen',
        errorMessage: state.docError!,
        onRetry: () => ref.read(_provider.notifier).loadDocumentsForSelected(),
      ).error();
    }
    if (_step == 0) {
      return AuditorRevisionSelectStep(
        auditors: state.allAuditors,
        selectedIds: state.selectedIds,
        onToggle: (id, sel) =>
            ref.read(_provider.notifier).toggleAuditor(id, sel),
        onNext: () async {
          await ref.read(_provider.notifier).loadDocumentsForSelected();
          if (mounted) setState(() => _step = 1);
        },
      );
    }

    // Map flat docs per selected auditor
    final selected = state.selectedAuditors;
    final docsByAuditor = <String, List<ExtDokumen>>{};
    for (var i = 0; i < selected.length; i++) {
      docsByAuditor[selected[i].id] =
          ref.read(_provider.notifier).docsForAuditor(i);
    }

    return AuditorRevisionDocsStep(
      auditors: selected,
      docsByAuditor: docsByAuditor,
      drafts: state.drafts,
      hasUnsavedEdits: state.hasUnsavedEdits,
      isSaving: state.isSaving,
      isSubmitting: state.isSubmitting,
      onPickFile: _pickFile,
      onPreviewFile: _previewFile,
      onNomorChanged: ref.read(_provider.notifier).setNomor,
      onTanggalPicked: _pickTanggal,
      onSave: _save,
      onSubmit: () => _submit(state),
    );
  }
}
