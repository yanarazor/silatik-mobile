import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/latik_profile.dart';
import '../../data/models/master_data_model.dart';
import '../../providers/master_data_provider.dart';
import '../../providers/profile_menu_provider.dart';
import '../../providers/registrasi_provider.dart';
import 'latik_profile_payload.dart';
import 'location_picker_field.dart';

class ProfilLembagaEditScreen extends ConsumerStatefulWidget {
  const ProfilLembagaEditScreen({super.key, required this.profile});

  final LatikProfile profile;

  @override
  ConsumerState<ProfilLembagaEditScreen> createState() =>
      _ProfilLembagaEditScreenState();
}

class _ProfilLembagaEditScreenState
    extends ConsumerState<ProfilLembagaEditScreen> {
  late final FormGroup form;
  late final String _noPendaftaran;

  bool _scopeAplikasi = false;
  bool _scopeInfrastruktur = false;
  LatLng? _position;
  bool _dirty = false;
  bool _saving = false;

  String? _lastProvinsi;
  String? _pendingKabupatenName;
  bool _provinsiResolved = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _noPendaftaran =
        p.noPendaftaran.isNotEmpty ? p.noPendaftaran : generateNoPendaftaran();

    final scope = _scopeFlags(p.scopeSource);
    _scopeAplikasi = scope.$1;
    _scopeInfrastruktur = scope.$2;

    _position = _parseLatLng(p.latitude, p.longitude);

    form = FormGroup({
      'nama_latik': FormControl<String>(
          value: p.namaLatik, validators: [Validators.required]),
      'email': FormControl<String>(value: p.email),
      'address':
          FormControl<String>(value: p.alamat, validators: [Validators.required]),
      'phone': FormControl<String>(
          value: p.phone, validators: [Validators.required]),
      'website': FormControl<String>(
          value: p.website, validators: [Validators.required]),
      'no_nib': FormControl<String>(value: p.noNib, validators: [
        Validators.required,
        Validators.pattern(r'^\d{13}$'),
      ]),
      'no_npwp': FormControl<String>(value: p.noNpwp, validators: [
        Validators.required,
        Validators.pattern(r'^\d{15,16}$'),
      ]),
      'area_operasional': FormControl<String>(value: p.areaOperasional),
      'provinsi': FormControl<String>(),
      'kabupaten': FormControl<String>(),
    });

    _pendingKabupatenName = p.kabupaten.isEmpty ? null : p.kabupaten;

    form.control('provinsi').valueChanges.listen((value) {
      final next = value?.toString();
      if (next == _lastProvinsi) return;
      _lastProvinsi = next;
      _pendingKabupatenName = null;
      form.control('kabupaten').reset();
      if (mounted) setState(() {});
    });

    form.valueChanges.listen((_) => _markDirty());
  }

  void _markDirty() {
    if (!_dirty && mounted) setState(() => _dirty = true);
  }

  (bool, bool) _scopeFlags(Object? raw) {
    bool has(String needle) {
      if (raw is Map) {
        for (final e in raw.entries) {
          final k = e.key.toString().toLowerCase();
          if (k.contains(needle)) {
            final v = e.value;
            return v == true ||
                v == 1 ||
                v == '1' ||
                (v is String &&
                    const {'true', 'aktif', 'active', 'ya', 'yes'}
                        .contains(v.trim().toLowerCase()));
          }
        }
        return false;
      }
      if (raw is List) {
        return raw.any((x) => x.toString().toLowerCase().contains(needle));
      }
      if (raw is String) {
        return raw.toLowerCase().contains(needle);
      }
      return false;
    }

    return (has('aplikasi'), has('infrastruktur'));
  }

  LatLng? _parseLatLng(String rawLat, String rawLng) {
    final lat = double.tryParse(rawLat.trim());
    final lng = double.tryParse(rawLng.trim());
    if (lat == null || lng == null) return null;
    if (lat == 0 && lng == 0) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty || _saving) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buang perubahan?'),
        content: const Text(
            'Perubahan yang belum disimpan akan hilang. Lanjutkan keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  bool _validate() {
    form.markAllAsTouched();
    if (form.invalid) {
      _snack('Lengkapi data wajib dengan benar');
      return false;
    }
    if (!_scopeAplikasi && !_scopeInfrastruktur) {
      _snack('Pilih minimal satu lingkup pendaftaran');
      return false;
    }
    if (_position == null) {
      _snack('Tentukan lokasi lembaga pada peta');
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);

    final pos = _position!;
    final payload = buildSaveProfilePayload(
      ref: widget.profile.latikRef,
      noPendaftaran: _noPendaftaran,
      namaLatik: (form.control('nama_latik').value ?? '').trim(),
      email: widget.profile.email,
      address: (form.control('address').value ?? '').trim(),
      phone: (form.control('phone').value ?? '').trim(),
      website: (form.control('website').value ?? '').trim(),
      noNib: (form.control('no_nib').value ?? '').trim(),
      noNpwp: (form.control('no_npwp').value ?? '').trim(),
      noStr: widget.profile.noStr,
      areaOperasional: (form.control('area_operasional').value ?? '').trim(),
      provinsiId: (form.control('provinsi').value ?? '').toString(),
      kabupatenId: (form.control('kabupaten').value ?? '').toString(),
      scopeAplikasi: _scopeAplikasi,
      scopeInfrastruktur: _scopeInfrastruktur,
      latitude: pos.latitude.toString(),
      longitude: pos.longitude.toString(),
    );

    try {
      await ref.read(latikServiceProvider).saveProfile(payload);
      ref.invalidate(latikProfileProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil lembaga diperbarui')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Gagal memperbarui profil');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard()) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Edit Profil Lembaga'),
        ),
        body: ReactiveForm(
          formGroup: form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
            children: [
              _label('Nomor Registrasi', theme, isRequired: false),
              _readOnlyField(_noPendaftaran, Icons.tag),
              _label('Nama Lembaga', theme),
              ReactiveTextField(
                formControlName: 'nama_latik',
                validationMessages: _requiredMsg('Nama lembaga'),
                decoration: const InputDecoration(
                  hintText: 'Nama lembaga',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
              ),
              _label('Email', theme, isRequired: false),
              _readOnlyField(
                widget.profile.email.isEmpty ? '-' : widget.profile.email,
                Icons.email_outlined,
              ),
              _label('NIB', theme),
              ReactiveTextField(
                formControlName: 'no_nib',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(13),
                ],
                validationMessages: {
                  ValidationMessage.required: (_) => 'NIB wajib diisi',
                  ValidationMessage.pattern: (_) =>
                      'NIB harus tepat 13 digit angka',
                },
                decoration: const InputDecoration(
                  hintText: '13 digit',
                  prefixIcon: Icon(Icons.badge_outlined),
                  counterText: '',
                ),
              ),
              _label('NPWP', theme),
              ReactiveTextField(
                formControlName: 'no_npwp',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ],
                validationMessages: {
                  ValidationMessage.required: (_) => 'NPWP wajib diisi',
                  ValidationMessage.pattern: (_) =>
                      'NPWP harus 15-16 digit angka',
                },
                decoration: const InputDecoration(
                  hintText: '15-16 digit',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                  counterText: '',
                ),
              ),
              if (widget.profile.noStr.isNotEmpty) ...[
                _label('Nomor STR', theme, isRequired: false),
                _readOnlyField(widget.profile.noStr, Icons.verified_outlined),
              ],
              _label('Alamat', theme),
              ReactiveTextField(
                formControlName: 'address',
                maxLines: 2,
                validationMessages: _requiredMsg('Alamat'),
                decoration: const InputDecoration(
                  hintText: 'Alamat lengkap lembaga',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              _label('Provinsi', theme),
              _provinsiDropdown(),
              _label('Kota/Kabupaten', theme),
              _kabupatenDropdown(),
              _label('Nomor Telepon', theme),
              ReactiveTextField(
                formControlName: 'phone',
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validationMessages: _requiredMsg('Nomor telepon'),
                decoration: const InputDecoration(
                  hintText: '08xxxxxxxxxx',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              _label('Website', theme),
              ReactiveTextField(
                formControlName: 'website',
                keyboardType: TextInputType.url,
                validationMessages: _requiredMsg('Website'),
                decoration: const InputDecoration(
                  hintText: 'www.contoh.com',
                  prefixIcon: Icon(Icons.language_outlined),
                ),
              ),
              _label('Area Operasional', theme, isRequired: false),
              ReactiveTextField(
                formControlName: 'area_operasional',
                decoration: const InputDecoration(
                  hintText: 'Contoh: Thamrin',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
              ),
              _label('Lingkup Pendaftaran', theme),
              _scopeCheckboxes(),
              _label('Lokasi Lembaga', theme),
              LocationPickerField(
                initial: _position,
                onChanged: (pos) {
                  _position = pos;
                  _markDirty();
                },
              ),
              const SizedBox(height: AppTheme.spacing24),
            ],
          ),
        ),
        bottomNavigationBar: _SaveBar(
          saving: _saving,
          onSave: _save,
        ),
      ),
    );
  }

  Widget _scopeCheckboxes() {
    return Column(
      children: [
        _ScopeTile(
          label: 'Aplikasi',
          value: _scopeAplikasi,
          onChanged: (v) {
            setState(() => _scopeAplikasi = v);
            _markDirty();
          },
        ),
        _ScopeTile(
          label: 'Infrastruktur',
          value: _scopeInfrastruktur,
          onChanged: (v) {
            setState(() => _scopeInfrastruktur = v);
            _markDirty();
          },
        ),
        // TODO: Intentionally disabled per current fe
        const _ScopeTile(
          label: 'Sekuriti (BSSN)',
          value: false,
          onChanged: null,
        ),
      ],
    );
  }

  Widget _provinsiDropdown() {
    final async = ref.watch(provinsiListProvider);
    return async.when(
      loading: () => const _DropdownLoading(),
      error: (_, __) => _DropdownError(
        hint: 'Gagal memuat provinsi',
        onRetry: () => ref.invalidate(provinsiListProvider),
      ),
      data: (list) {
        _resolveProvinsiPrefill(list);
        return ReactiveDropdownField<String>(
          formControlName: 'provinsi',
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: 'Pilih Provinsi',
            prefixIcon: Icon(Icons.map_outlined),
          ),
          items: list
              .map((ProvinsiModel e) =>
                  DropdownMenuItem(value: e.id, child: Text(e.nama)))
              .toList(),
        );
      },
    );
  }

  void _resolveProvinsiPrefill(List<ProvinsiModel> list) {
    if (_provinsiResolved) return;
    _provinsiResolved = true;
    final name = widget.profile.provinsi.trim().toLowerCase();
    if (name.isEmpty) return;
    ProvinsiModel? match;
    for (final e in list) {
      if (e.nama.trim().toLowerCase() == name) {
        match = e;
        break;
      }
    }
    if (match == null) return;
    _lastProvinsi = match.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      form.control('provinsi').value = match!.id;
    });
  }

  Widget _kabupatenDropdown() {
    final provinsiId = form.control('provinsi').value?.toString();
    if (provinsiId == null || provinsiId.isEmpty) {
      return ReactiveDropdownField<String>(
        formControlName: 'kabupaten',
        decoration: const InputDecoration(
          hintText: 'Pilih Provinsi dulu',
          prefixIcon: Icon(Icons.location_city_outlined),
        ),
        items: const [],
      );
    }
    final async = ref.watch(kabupatenListProvider(provinsiId));
    return async.when(
      loading: () => const _DropdownLoading(),
      error: (_, __) => _DropdownError(
        hint: 'Gagal memuat kabupaten',
        onRetry: () => ref.invalidate(kabupatenListProvider(provinsiId)),
      ),
      data: (list) {
        _resolveKabupatenPrefill(list);
        return ReactiveDropdownField<String>(
          formControlName: 'kabupaten',
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: 'Pilih Kota/Kabupaten',
            prefixIcon: Icon(Icons.location_city_outlined),
          ),
          items: list
              .map((KabupatenModel e) =>
                  DropdownMenuItem(value: e.id, child: Text(e.nama)))
              .toList(),
        );
      },
    );
  }

  void _resolveKabupatenPrefill(List<KabupatenModel> list) {
    final pendingName = _pendingKabupatenName?.trim().toLowerCase();
    if (pendingName == null || pendingName.isEmpty) return;
    KabupatenModel? match;
    for (final e in list) {
      if (e.nama.trim().toLowerCase() == pendingName) {
        match = e;
        break;
      }
    }
    if (match == null) return;
    _pendingKabupatenName = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (form.control('kabupaten').value != match!.id) {
        form.control('kabupaten').value = match.id;
        setState(() {});
      }
    });
  }

  Widget _readOnlyField(String value, IconData icon) {
    return InputDecorator(
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF1F4F9),
      ),
      child: Text(
        value,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
      ),
    );
  }
  
  Map<String, String Function(Object)> _requiredMsg(String field) => {
        ValidationMessage.required: (_) => '$field wajib diisi',
      };

  Widget _label(String text, ThemeData theme, {bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(
          bottom: AppTheme.spacing8, top: AppTheme.spacing16),
      child: RichText(
        text: TextSpan(
          text: text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          children: isRequired
              ? [
                  TextSpan(
                    text: ' *',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: AppColors.error),
                  ),
                ]
              : const [],
        ),
      ),
    );
  }
}

class _ScopeTile extends StatelessWidget {
  const _ScopeTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;
    return CheckboxListTile(
      value: value,
      onChanged: disabled ? null : (v) => onChanged!(v ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      title: Text(
        label,
        style: TextStyle(
          color: disabled ? AppColors.textSecondary : AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: disabled
          ? const Text('Belum tersedia',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11))
          : null,
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.saving, required this.onSave});

  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4ECF7))),
        boxShadow: [
          BoxShadow(
            color: Color(0x140C2D5C),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded, size: 20),
            label: Text(saving ? 'Menyimpan...' : 'Simpan'),
          ),
        ),
      ),
    );
  }
}

class _DropdownLoading extends StatelessWidget {
  const _DropdownLoading();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
}

class _DropdownError extends StatelessWidget {
  const _DropdownError({required this.hint, required this.onRetry});
  final String hint;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onRetry,
        child: InputDecorator(
          decoration: InputDecoration(
            hintText: hint,
            errorText: 'Tap untuk coba lagi',
            prefixIcon: const Icon(Icons.error_outline),
          ),
          child: const SizedBox(height: 20),
        ),
      );
}
