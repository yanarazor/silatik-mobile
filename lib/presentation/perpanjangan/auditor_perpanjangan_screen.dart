import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/api_error_handler.dart';
import '../../data/models/auditor_model.dart';
import '../../providers/auditor_ext_provider.dart';
import '../../providers/invoice_provider.dart';
import '../shared/confirm_dialog.dart';
import '../shared/step_indicator.dart';
import '../shared/wizard_header.dart';
import 'auditor/steps/auditor_doc_page.dart';
import 'auditor/steps/doc_hub_step.dart';
import 'auditor/steps/konfirmasi_step.dart';
import 'auditor/steps/select_step.dart';

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
        builder: (_) => AuditorDocPage(
            refExt: _key, auditorIndex: index, auditor: auditor),
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
    final state = ref.watch(auditorExtProvider(_key));
    const titles = ['Pilih Auditor', 'Dokumen Pendukung', 'Konfirmasi'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFE),
      body: SafeArea(
        child: Column(
          children: [
            WizardHeader(
              title: 'Perpanjangan Auditor',
              subtitle: '${titles[_step]} • Langkah ${_step + 1} dari 3',
              onBack: state.submitting
                  ? null
                  : () {
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

  Widget _buildStep(AuditorExtState state) {
    switch (_step) {
      case 0:
        return SelectStep(
          selected: _selected,
          busy: state.submitting,
          onToggle: _toggle,
          onNext: _continueFromSelect,
        );
      case 1:
        return DocHubStep(
          refExt: _key,
          selected: _selected,
          state: state,
          onOpen: _openDocPage,
          onRetry: _continueFromSelect,
          onNext: _goKonfirmasi,
        );
      default:
        return KonfirmasiStep(
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