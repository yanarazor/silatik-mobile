import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/api_error_handler.dart';
import '../../../../data/models/latik_experience.dart';

class ExperienceFormSheet extends StatefulWidget {
  const ExperienceFormSheet({
    super.key,
    this.initial,
    required this.onSubmit,
  });

  final LatikExperience? initial;
  final Future<void> Function(LatikExperience experience) onSubmit;

  @override
  State<ExperienceFormSheet> createState() => _ExperienceFormSheetState();
}

class _ExperienceFormSheetState extends State<ExperienceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ippdPengguna;
  late final TextEditingController _objectAudit;
  String? _tahun;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tahun = widget.initial?.tahun;
    _ippdPengguna =
        TextEditingController(text: widget.initial?.ippdPengguna ?? '');
    _objectAudit =
        TextEditingController(text: widget.initial?.objectAudit ?? '');
  }

  @override
  void dispose() {
    _ippdPengguna.dispose();
    _objectAudit.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final initial = widget.initial;
    final experience = LatikExperience(
      id: initial?.id,
      ref: initial?.ref ?? '',
      tahun: _tahun!,
      ippdPengguna: _ippdPengguna.text.trim(),
      objectAudit: _objectAudit.text.trim(),
    );

    try {
      await widget.onSubmit(experience);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = ApiErrorHandler.messageFrom(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppTheme.spacing20,
          AppTheme.spacing16,
          AppTheme.spacing20,
          MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacing16,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
                Text(
                  editing ? 'Edit Pengalaman LATIK' : 'Tambah Pengalaman LATIK',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing20),
                _yearPicker(),
                const SizedBox(height: AppTheme.spacing12),
                TextFormField(
                  controller: _ippdPengguna,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'IPPD Pengguna',
                    hintText: 'Institusi Pengguna Pengalaman Latik',
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'IPPD Pengguna wajib diisi'
                      : null,
                ),
                const SizedBox(height: AppTheme.spacing12),
                TextFormField(
                  controller: _objectAudit,
                  minLines: 2,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submitting ? null : _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Obyek Audit',
                    hintText: 'Obyek Kegiatan / Audit Pengalaman Latik',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Obyek Audit wajib diisi'
                      : null,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacing20),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          editing ? 'Simpan Perubahan' : 'Tambah Pengalaman'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _yearPicker() {
    final now = DateTime.now().year;
    final years = [for (var year = now; year >= now - 40; year--) '$year'];
    final currentValue = _tahun;
    if (currentValue != null && !years.contains(currentValue)) {
      years.add(currentValue);
    }

    return DropdownButtonFormField<String>(
      initialValue: _tahun,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Tahun',
        prefixIcon: Icon(Icons.calendar_today_outlined),
      ),
      items: [
        for (final year in years)
          DropdownMenuItem(value: year, child: Text(year)),
      ],
      validator: (value) =>
          value == null || value.length != 4 ? 'Tahun wajib dipilih' : null,
      onChanged: (value) => setState(() => _tahun = value),
    );
  }
}
