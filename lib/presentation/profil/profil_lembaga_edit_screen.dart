import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/latik_profile.dart';
import '../../providers/latik_service_provider.dart';
import '../../providers/profile_menu_provider.dart';
import 'latik_profile_payload.dart';
import 'widgets/lembaga/lembaga_form_body.dart';
import 'widgets/lembaga/save_bar.dart';

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
        body: LembagaFormBody(
          form: form,
          profile: widget.profile,
          noPendaftaran: _noPendaftaran,
          position: _position,
          scopeAplikasi: _scopeAplikasi,
          scopeInfrastruktur: _scopeInfrastruktur,
          onScopeAplikasi: (v) {
            setState(() => _scopeAplikasi = v);
            _markDirty();
          },
          onScopeInfrastruktur: (v) {
            setState(() => _scopeInfrastruktur = v);
            _markDirty();
          },
          onPositionChanged: (pos) {
            _position = pos;
            _markDirty();
          },
        ),
        bottomNavigationBar: SaveBar(
          saving: _saving,
          onSave: _save,
        ),
      ),
    );
  }
}