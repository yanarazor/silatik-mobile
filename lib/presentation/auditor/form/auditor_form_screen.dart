import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/auditor_model.dart';
import '../../../providers/auditor_form_provider.dart';
import '../../../providers/auditor_provider.dart';
import '../../shared/step_indicator.dart';
import 'auditor_data_dukung_step.dart';
import 'auditor_profil_step.dart';
import 'auditor_sertifikasi_body.dart';
import 'auditor_success_screen.dart';

/// Buka form Tambah (initial=null) atau Ubah (initial=auditor) auditor.
/// Mengembalikan `true` bila ada perubahan tersimpan.
Future<bool?> openAuditorForm(BuildContext context, {AuditorModel? initial}) {
  return Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(builder: (_) => AuditorFormScreen(initial: initial)),
  );
}

/// Auditor form screen.
/// - Add: 2-step wizard (Profil → Data Dukung), then a success screen that
///   offers adding Technical Certification (optional).
/// - Edit: freely clickable tabs (Profil / Data Dukung / Technical Certification).
class AuditorFormScreen extends ConsumerStatefulWidget {
  const AuditorFormScreen({super.key, this.initial});

  final AuditorModel? initial;

  @override
  ConsumerState<AuditorFormScreen> createState() => _AuditorFormScreenState();
}

class _AuditorFormScreenState extends ConsumerState<AuditorFormScreen> {
  /// Tab index (edit) / step (create). Create: 0=Profil, 1=Data Dukung.
  /// Edit: 0=Profil, 1=Data Dukung, 2=Technical Certification.
  int _tab = 0;

  /// Create: true after a successful save → show the success screen.
  bool _saved = false;
  bool _prefillStarted = false;

  String? get _formKey => widget.initial?.id;
  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
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
    ref
        .read(auditorFormProvider(_formKey).notifier)
        .initFromAuditor(auditor, docs);
  }

  void _finish() {
    ref.invalidate(auditorListProvider);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Keep the notifier alive while the screen is open (autoDispose).
    ref.watch(auditorFormProvider(_formKey));

    final titles = _isEdit
        ? const ['Profil Auditor', 'Data Dukung', 'Sertifikasi Teknis']
        : const ['Profil Auditor', 'Data Dukung'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFE),
      body: SafeArea(
        child: Column(
          children: [
            _header(theme, titles),
            if (_isEdit)
              _tabBar(theme, titles)
            else if (!_saved) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: StepIndicator(current: _tab, total: 2),
              ),
              const SizedBox(height: 18),
            ] else
              const SizedBox(height: 18),
            Expanded(child: _content()),
          ],
        ),
      ),
    );
  }

  Widget _header(ThemeData theme, List<String> titles) {
    // Subtitle: create+wizard shows "Langkah X dari N", otherwise the tab title.
    final showSteps = !_isEdit && !_saved;
    final subtitle = _saved
        ? 'Selesai'
        : showSteps
            ? '${titles[_tab]} • Langkah ${_tab + 1} dari ${titles.length}'
            : titles[_tab];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 22, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.primary),
            onPressed: _onBack,
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
                  subtitle,
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
    );
  }

  void _onBack() {
    // Create wizard: step back one first; otherwise close the screen.
    if (!_isEdit && !_saved && _tab > 0) {
      setState(() => _tab -= 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _tabBar(ThemeData theme, List<String> titles) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      child: Row(
        children: [
          for (var i = 0; i < titles.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () => setState(() => _tab = i),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _tab == i
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      titles[i],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _tab == i
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            _tab == i ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _content() {
    // Create success: success screen (offer Technical Certification).
    if (!_isEdit && _saved) {
      final ref = this.ref.read(auditorFormProvider(_formKey)).ref ?? '';
      return AuditorSuccessScreen(auditorRef: ref, onFinish: _finish);
    }

    switch (_tab) {
      case 0:
        return AuditorProfilStep(
          formKey: _formKey,
          onNext: () => setState(() => _tab = 1),
        );
      case 1:
        return AuditorDataDukungStep(
          formKey: _formKey,
          onBack: () => setState(() => _tab = 0),
          onSaved: () {
            // Create: show the success screen. Edit: stay on the tab (data
            // is saved, user can switch tabs freely).
            if (_isEdit) return;
            setState(() => _saved = true);
          },
        );
      default: // 2 — edit mode only
        return AuditorSertifikasiBody(formKey: _formKey);
    }
  }
}
