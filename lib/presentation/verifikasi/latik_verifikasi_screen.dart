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
import '../../core/utils/url_opener.dart';
import '../../data/models/latik_profile.dart';
import '../../data/models/profil_dokumen.dart';
import '../../data/models/registrasi_model.dart';
import '../../data/services/latik_service.dart';
import '../../providers/auditor_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/latik_verifikasi_provider.dart';
import '../../providers/profile_menu_provider.dart';
import '../auditor/form/auditor_profil_step.dart' show kAuditorFileMaxBytes;
import '../shared/confirm_dialog.dart';
import '../shared/step_indicator.dart';
import '../shared/wizard_header.dart';
import 'steps/auditor_step.dart';
import 'steps/data_step.dart';
import 'steps/dokumen_step.dart';
import 'steps/konfirmasi_step.dart';

class LatikVerifikasiScreen extends ConsumerStatefulWidget {
  const LatikVerifikasiScreen({super.key, required this.profile});

  final LatikProfile profile;

  @override
  ConsumerState<LatikVerifikasiScreen> createState() =>
      _LatikVerifikasiScreenState();
}

class _LatikVerifikasiScreenState
    extends ConsumerState<LatikVerifikasiScreen> {
  int _step = 0;

  final Map<int, DocEdit> _edits = {};
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
      _edits[d.id!] = DocEdit(
        file: d.url.trim().isEmpty
            ? null
            : FileItem(path: d.url, name: fileNameFromUrl(d.url), size: 0),
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
        tanggal: e.tanggal == null ? null : formatDocDate(e.tanggal!),
      ));
    }
    return uploads;
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
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
            WizardHeader(
              title: 'Ajukan Verifikasi',
              subtitle: '${titles[_step]} • Langkah ${_step + 1} dari 4',
              onBack: state.submitting ? null : _back,
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
        return DataStep(profile: widget.profile, onNext: _next);
      case 1:
        return DokumenStep(
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
        return AuditorStep(
          latikRef: _latikRef,
          auditorsAsync: ref.watch(auditorListProvider),
          onRetry: () => ref.invalidate(auditorListProvider),
          onBack: _back,
          onNext: _fromAuditor,
        );
      default:
        return KonfirmasiStep(
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
}