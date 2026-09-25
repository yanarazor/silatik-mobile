import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/registrasi_model.dart';
import '../../../providers/auditor_form_provider.dart';
import '../../shared/field_label.dart';
import 'widgets/profil_step_fields.dart';

/// Batas ukuran foto/sertifikat per dokumen (10MB, sesuai handover doc).
/// FileUtils.maxSizeBytes tetap 5MB untuk alur registrasi lain.
const int kAuditorFileMaxBytes = 10 * 1024 * 1024;

/// Step 0 — Profil Auditor. Menulis AuditorProfilDraft ke auditorFormProvider
/// saat [onNext] tervalidasi.
class AuditorProfilStep extends ConsumerStatefulWidget {
  const AuditorProfilStep({
    super.key,
    required this.formKey,
    required this.onNext,
  });

  /// Key family auditorFormProvider (null = create, ref = edit).
  final String? formKey;
  final VoidCallback onNext;

  @override
  ConsumerState<AuditorProfilStep> createState() => _AuditorProfilStepState();
}

class _AuditorProfilStepState extends ConsumerState<AuditorProfilStep> {
  late final FormGroup form;
  DateTime? _tanggalLahir;
  FileItem? _foto;
  bool _prefilled = false;
  String? _lastProvinsi;
  String? _pendingKabupaten;

  @override
  void initState() {
    super.initState();
    form = FormGroup({
      'nama': FormControl<String>(validators: [Validators.required]),
      'nik': FormControl<String>(validators: [Validators.required]),
      'email': FormControl<String>(
          validators: [Validators.required, Validators.email]),
      'tempat_lahir': FormControl<String>(validators: [Validators.required]),
      'phone': FormControl<String>(),
      'provinsi': FormControl<String>(),
      'kabupaten': FormControl<String>(),
      'kode_post': FormControl<String>(),
      'agama': FormControl<String>(),
      'status': FormControl<String>(value: '1'),
      'keterangan': FormControl<String>(),
    });
    form.control('provinsi').valueChanges.listen((value) {
      final next = value?.toString();
      if (next == _lastProvinsi) return; // tak ada perubahan nyata
      _lastProvinsi = next;
      _pendingKabupaten = null; // pilihan lama tak relevan untuk provinsi baru
      form.control('kabupaten').reset();
      if (mounted) setState(() {});
    });
  }

  /// Prefill dari draft di provider. Dalam mode edit, draft baru terisi setelah
  /// initFromAuditor (yang menunggu fetch dokumen), jadi prefill dibiarkan
  /// retryable: baru dikunci (`_prefilled=true`) begitu ada data nyata.
  void _prefill(AuditorProfilDraft p) {
    if (_prefilled) return;
    final hasData = p.nama.isNotEmpty ||
        p.nik.isNotEmpty ||
        p.email.isNotEmpty ||
        p.tanggalLahir != null ||
        p.foto != null;
    if (!hasData) return; // tunggu draft terisi (async edit)
    _lastProvinsi = p.provinsi;
    _pendingKabupaten = p.kabupaten.isEmpty ? null : p.kabupaten;
    form.patchValue({
      'nama': p.nama,
      'nik': p.nik,
      'email': p.email,
      'tempat_lahir': p.tempatLahir,
      'phone': p.phone,
      'provinsi': p.provinsi,
      'kabupaten': p.kabupaten,
      'kode_post': p.kodePos,
      'agama': p.agama,
      'status': p.status.isEmpty ? '1' : p.status,
      'keterangan': p.keterangan,
    });
    _tanggalLahir = p.tanggalLahir;
    _foto = p.foto;
    _prefilled = true;
  }

  static const _fotoExts = ['jpg', 'jpeg', 'png', 'gif', 'svg', 'webp'];

  Future<void> _pickFoto() async {
    // FileType.image memakai galeri/foto native di iOS (bukan hanya Files).
    final result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;
    final file = result.files.single;
    final ext = (file.extension ?? '').toLowerCase();
    if (ext.isNotEmpty && !_fotoExts.contains(ext)) {
      _snack('Format foto harus jpg, png, gif, svg, atau webp');
      return;
    }
    if (file.size > kAuditorFileMaxBytes) {
      _snack('Ukuran foto maksimal 10MB');
      return;
    }
    setState(() => _foto =
        FileItem(path: file.path ?? '', name: file.name, size: file.size));
  }

  bool _validateAndSave() {
    form.markAllAsTouched();
    if (kDebugMode) {
      debugPrint('=== PROFIL AUDITOR SUBMIT ===');
      debugPrint('form.rawValue: ${form.rawValue}');
      debugPrint('tanggal_lahir: $_tanggalLahir');
      debugPrint('foto: ${_foto?.name} (${_foto?.path})');
    }
    final nik = form.control('nik').value?.toString();
    if (form.invalid) {
      _snack('Lengkapi data wajib');
      return false;
    }
    if (AppValidators.nik(nik) != null) {
      _snack('NIK harus 16 digit angka');
      return false;
    }
    if (_tanggalLahir == null) {
      _snack('Tanggal lahir wajib diisi');
      return false;
    }
    if (_foto == null) {
      _snack('Foto auditor wajib diunggah');
      return false;
    }
    final phone = form.control('phone').value?.toString() ?? '';
    if (phone.isNotEmpty && !RegExp(r'^\d+$').hasMatch(phone)) {
      _snack('Nomor telepon hanya boleh angka');
      return false;
    }
    final kodePos = form.control('kode_post').value?.toString() ?? '';
    if (kodePos.isNotEmpty && !RegExp(r'^\d+$').hasMatch(kodePos)) {
      _snack('Kode pos hanya boleh angka');
      return false;
    }

    ref.read(auditorFormProvider(widget.formKey).notifier).setProfil(
          AuditorProfilDraft(
            nama: form.control('nama').value ?? '',
            nik: nik ?? '',
            email: form.control('email').value ?? '',
            tempatLahir: form.control('tempat_lahir').value ?? '',
            tanggalLahir: _tanggalLahir,
            phone: phone,
            provinsi: form.control('provinsi').value ?? '',
            kabupaten: form.control('kabupaten').value ?? '',
            kodePos: kodePos,
            agama: form.control('agama').value ?? '',
            status: form.control('status').value ?? '1',
            keterangan: form.control('keterangan').value ?? '',
            foto: _foto,
          ),
        );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Watch profil supaya build ulang saat draft edit terisi (async), lalu
    // prefill form. Retryable sampai data benar-benar ada.
    final profil =
        ref.watch(auditorFormProvider(widget.formKey).select((s) => s.profil));
    _prefill(profil);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: ReactiveForm(
        formGroup: form,
        child: ListView(
          children: [
            const FieldLabel('Nama Lengkap'),
            ReactiveTextField(
              formControlName: 'nama',
              decoration: const InputDecoration(
                hintText: 'Nama auditor',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const FieldLabel('NIK'),
            ReactiveTextField(
              formControlName: 'nik',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
              ],
              decoration: const InputDecoration(
                hintText: '16 digit',
                prefixIcon: Icon(Icons.badge_outlined),
                counterText: '',
              ),
            ),
            const FieldLabel('Email'),
            ReactiveTextField(
              formControlName: 'email',
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'email@contoh.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const FieldLabel('Tempat Lahir'),
            ReactiveTextField(
              formControlName: 'tempat_lahir',
              decoration: const InputDecoration(
                hintText: 'Kota kelahiran',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
            ),
            const FieldLabel('Tanggal Lahir'),
            DateField(
              value: _tanggalLahir,
              onPick: (d) => setState(() => _tanggalLahir = d),
            ),
            const FieldLabel('Nomor Telepon', isRequired: false),
            ReactiveTextField(
              formControlName: 'phone',
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '08xxxxxxxxxx',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const FieldLabel('Provinsi', isRequired: false),
            ProfilWilayahFields(
              form: form,
              pendingKabupaten: _pendingKabupaten,
              onKabupatenApplied: () {
                _pendingKabupaten = null;
                setState(() {});
              },
            ),
            const FieldLabel('Kode Pos', isRequired: false),
            ReactiveTextField(
              formControlName: 'kode_post',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                hintText: 'Contoh: 12345',
                prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                counterText: '',
              ),
            ),
            const FieldLabel('Agama', isRequired: false),
            AgamaDropdown(form: form),
            const FieldLabel('Status Auditor', isRequired: false),
            ReactiveDropdownField<String>(
              formControlName: 'status',
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.verified_user_outlined),
              ),
              items: const [
                DropdownMenuItem(value: '1', child: Text('Tetap')),
                DropdownMenuItem(value: '0', child: Text('Tidak Tetap')),
              ],
            ),
            const FieldLabel('Keterangan', isRequired: false),
            ReactiveTextField(
              formControlName: 'keterangan',
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Catatan (opsional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            FotoField(foto: _foto, onPick: _pickFoto),
            const SizedBox(height: AppTheme.spacing24),
            ElevatedButton(
              onPressed: () {
                if (_validateAndSave()) widget.onNext();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
              ),
              child: const Text('Selanjutnya'),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }
}