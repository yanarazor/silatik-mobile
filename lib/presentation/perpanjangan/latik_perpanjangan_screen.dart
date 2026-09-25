import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/api_error_handler.dart';
import '../../core/utils/url_opener.dart';
import '../../data/models/registrasi_model.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/latik_ext_provider.dart';
import '../auditor/form/auditor_profil_step.dart' show kAuditorFileMaxBytes;
import '../shared/confirm_dialog.dart';
import '../shared/step_indicator.dart';
import '../shared/wizard_header.dart';
import 'latik/steps/data_latik_step.dart';
import 'latik/steps/dokumen_step.dart';
import 'latik/steps/konfirmasi_step.dart';

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
    final state = ref.watch(latikExtProvider(_key));
    const titles = ['Data LATIK', 'Dokumen Pendukung', 'Konfirmasi'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFE),
      body: SafeArea(
        child: Column(
          children: [
            WizardHeader(
              title: 'Perpanjangan LATIK',
              subtitle: '${titles[_step]} • Langkah ${_step + 1} dari 3',
              onBack: () {
                if (_step > 0) {
                  setState(() => _step -= 1);
                } else {
                  Navigator.of(context).pop();
                }
              },
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
        return DataLatikStep(onNext: _goDokumen);
      case 1:
        return DokumenStep(
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
        return KonfirmasiStep(
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