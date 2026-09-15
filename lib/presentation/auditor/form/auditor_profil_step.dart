import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/url_opener.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/master_data_model.dart';
import '../../../data/models/registrasi_model.dart';
import '../../../providers/auditor_form_provider.dart';
import '../../../providers/master_data_provider.dart';
import 'auditor_dokumen_card.dart';

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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: ReactiveForm(
        formGroup: form,
        child: ListView(
          children: [
            _label('Nama Lengkap', theme),
            ReactiveTextField(
              formControlName: 'nama',
              decoration: const InputDecoration(
                hintText: 'Nama auditor',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            _label('NIK', theme),
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
            _label('Email', theme),
            ReactiveTextField(
              formControlName: 'email',
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'email@contoh.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            _label('Tempat Lahir', theme),
            ReactiveTextField(
              formControlName: 'tempat_lahir',
              decoration: const InputDecoration(
                hintText: 'Kota kelahiran',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
            ),
            _label('Tanggal Lahir', theme),
            _datePicker(theme),
            _label('Nomor Telepon', theme, isRequired: false),
            ReactiveTextField(
              formControlName: 'phone',
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '08xxxxxxxxxx',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            _label('Provinsi', theme, isRequired: false),
            _provinsiDropdown(),
            _label('Kota/Kabupaten', theme, isRequired: false),
            _kabupatenDropdown(),
            _label('Kode Pos', theme, isRequired: false),
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
            _label('Agama', theme, isRequired: false),
            _agamaDropdown(),
            _label('Status Auditor', theme, isRequired: false),
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
            _label('Keterangan', theme, isRequired: false),
            ReactiveTextField(
              formControlName: 'keterangan',
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Catatan (opsional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _fotoCard(),
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

  Widget _datePicker(ThemeData theme) {
    final hasValue = _tanggalLahir != null;
    // Pakai InputDecorator agar tampilannya sama persis dengan field lain.
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          firstDate: DateTime(1940),
          lastDate: DateTime.now(),
          initialDate: _tanggalLahir ?? DateTime(1990),
        );
        if (date != null) setState(() => _tanggalLahir = date);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.cake_outlined),
          suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          hasValue
              ? _tanggalLahir!.toString().split(' ').first
              : 'Pilih tanggal lahir',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: hasValue ? AppColors.textPrimary : theme.hintColor,
          ),
        ),
      ),
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
      data: (list) => ReactiveDropdownField<String>(
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
      ),
    );
  }

  Widget _kabupatenDropdown() {
    final provinsiId = form.control('provinsi').value?.toString();
    if (provinsiId == null || provinsiId.isEmpty) {
      return ReactiveDropdownField<String>(
        formControlName: 'kabupaten',
        decoration: const InputDecoration(
          hintText: 'Pilih Provinsi dulu',
          prefixIcon: Icon(Icons.location_on_outlined),
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
        final pending = _pendingKabupaten;
        if (pending != null &&
            form.control('kabupaten').value != pending &&
            list.any((e) => e.id == pending)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            form.control('kabupaten').value = pending;
            _pendingKabupaten = null;
            setState(() {});
          });
        }
        return ReactiveDropdownField<String>(
          formControlName: 'kabupaten',
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: 'Pilih Kota/Kabupaten',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          items: list
              .map((KabupatenModel e) =>
                  DropdownMenuItem(value: e.id, child: Text(e.nama)))
              .toList(),
        );
      },
    );
  }

  Widget _agamaDropdown() {
    final async = ref.watch(agamaListProvider);
    return async.when(
      loading: () => const _DropdownLoading(),
      // Agama opsional: kalau endpoint gagal, jangan blokir form.
      error: (_, __) => ReactiveDropdownField<String>(
        formControlName: 'agama',
        decoration: const InputDecoration(
          hintText: 'Agama tidak tersedia',
          prefixIcon: Icon(Icons.self_improvement_outlined),
        ),
        items: const [],
      ),
      data: (list) => ReactiveDropdownField<String>(
        formControlName: 'agama',
        isExpanded: true,
        decoration: const InputDecoration(
          hintText: 'Pilih Agama',
          prefixIcon: Icon(Icons.self_improvement_outlined),
        ),
        items: list
            .map((AgamaModel e) =>
                DropdownMenuItem(value: e.id, child: Text(e.nama)))
            .toList(),
      ),
    );
  }

  Widget _fotoCard() {
    return AuditorDokumenCard(
      title: 'Foto Auditor',
      requiredDoc: true,
      file: _foto,
      onPick: _pickFoto,
      onPreview: _previewFoto,
      leadingIcon: Icons.image_outlined,
      leadingColor: AppColors.primary,
      formatHint: 'Format JPG/PNG (maks. 10 MB)',
      imageThumbnail: true,
    );
  }

  Future<void> _previewFoto() async {
    final path = _foto?.path.trim() ?? '';
    if (path.isEmpty) return;
    if (path.toLowerCase().startsWith('http')) {
      await openFileUrl(context, path);
      return;
    }
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && mounted) {
      _snack('Gagal membuka foto: ${result.message}');
    }
  }

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

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
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
