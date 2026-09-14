import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/auditor_model.dart';
import '../../../providers/auditor_form_provider.dart';
import '../../../providers/auditor_provider.dart';
import '../../registration/widgets/step_indicator.dart';
import 'auditor_data_dukung_step.dart';
import 'auditor_profil_step.dart';
import 'auditor_sertifikasi_step.dart';

/// Buka form Tambah (initial=null) atau Ubah (initial=auditor) auditor.
/// Mengembalikan `true` bila ada perubahan tersimpan.
Future<bool?> openAuditorForm(BuildContext context, {AuditorModel? initial}) {
  return Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(builder: (_) => AuditorFormScreen(initial: initial)),
  );
}

/// Layar form Tambah/Ubah Auditor: 3 langkah (Profil → Data Dukung →
/// Sertifikasi Teknis). [initial] non-null = mode edit.
class AuditorFormScreen extends ConsumerStatefulWidget {
  const AuditorFormScreen({super.key, this.initial});

  final AuditorModel? initial;

  @override
  ConsumerState<AuditorFormScreen> createState() => _AuditorFormScreenState();
}

class _AuditorFormScreenState extends ConsumerState<AuditorFormScreen> {
  int _step = 0;
  bool _prefillStarted = false;

  /// Key family provider: ref auditor saat edit, null saat create.
  String? get _formKey => widget.initial?.id;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      // Prefill setelah frame pertama (butuh ref & dokumen dari server).
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefillEdit());
    }
  }

  Future<void> _prefillEdit() async {
    if (_prefillStarted) return;
    _prefillStarted = true;
    final auditor = widget.initial!;
    List<AuditorDocument> docs = const [];
    try {
      docs = await ref.read(auditorRepoProvider).getDocuments(auditor.id);
    } catch (_) {
      // Kalau gagal ambil dokumen, tetap prefill profil; user bisa reupload.
    }
    if (!mounted) return;
    ref.read(auditorFormProvider(_formKey).notifier).initFromAuditor(auditor, docs);
  }

  void _finish() {
    // Refresh daftar auditor lalu tutup layar.
    ref.invalidate(auditorListProvider);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Jaga notifier tetap hidup selama layar terbuka supaya data profil &
    // dokumen tidak hilang saat pindah/kembali antar langkah (autoDispose).
    ref.watch(auditorFormProvider(_formKey));
    const titles = ['Profil Auditor', 'Data Dukung', 'Sertifikasi Teknis'];

    final steps = [
      AuditorProfilStep(
        formKey: _formKey,
        onNext: () => setState(() => _step = 1),
      ),
      AuditorDataDukungStep(
        formKey: _formKey,
        onBack: () => setState(() => _step = 0),
        onSaved: () => setState(() => _step = 2),
      ),
      AuditorSertifikasiStep(
        formKey: _formKey,
        onBack: () => setState(() => _step = 1),
        onFinish: _finish,
      ),
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
                          _isEdit ? 'Ubah Auditor' : 'Tambah Auditor',
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
            Expanded(child: steps[_step]),
          ],
        ),
      ),
    );
  }
}
