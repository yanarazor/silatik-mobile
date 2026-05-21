import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/provinces.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/lembaga_model.dart';
import '../../../providers/registrasi_provider.dart';

class Step1DataLembaga extends ConsumerStatefulWidget {
  const Step1DataLembaga({super.key});

  @override
  ConsumerState<Step1DataLembaga> createState() => _Step1DataLembagaState();
}

class _Step1DataLembagaState extends ConsumerState<Step1DataLembaga> {
  final form = FormGroup({
    'nama': FormControl<String>(validators: [Validators.required]),
    'nib': FormControl<String>(validators: [Validators.required]),
    'badan': FormControl<String>(),
    'alamat': FormControl<String>(validators: [Validators.required]),
    'provinsi': FormControl<String>(validators: [Validators.required]),
    'kota': FormControl<String>(validators: [Validators.required]),
    'kodePos': FormControl<String>(),
    'telepon': FormControl<String>(validators: [Validators.required]),
    'email': FormControl<String>(
        validators: [Validators.required, Validators.email]),
    'website': FormControl<String>(),
  });
  bool _prefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lembaga = ref.read(registrasiProvider).data.lembaga;
    if (lembaga != null && !_prefilled) {
      form.patchValue({
        'nama': lembaga.nama,
        'nib': lembaga.nib,
        'badan': lembaga.badanHukum,
        'alamat': lembaga.alamat,
        'provinsi': lembaga.provinsi,
        'kota': lembaga.kota,
        'kodePos': lembaga.kodePos,
        'telepon': lembaga.telepon,
        'email': lembaga.email,
        'website': lembaga.website,
      });
      _prefilled = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lembaga = ref.watch(registrasiProvider.select((s) => s.data.lembaga));
    if (lembaga != null && !_prefilled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _prefilled) return;
        form.patchValue({
          'nama': lembaga.nama,
          'nib': lembaga.nib,
          'badan': lembaga.badanHukum,
          'alamat': lembaga.alamat,
          'provinsi': lembaga.provinsi,
          'kota': lembaga.kota,
          'kodePos': lembaga.kodePos,
          'telepon': lembaga.telepon,
          'email': lembaga.email,
          'website': lembaga.website,
        });
        _prefilled = true;
      });
    }

    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Data Lembaga',
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Expanded(
            child: ReactiveForm(
              formGroup: form,
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing24),
                children: [
                  _buildLabel('Nama Lembaga', textTheme: textTheme),
                  ReactiveTextField(
                    formControlName: 'nama',
                    decoration: const InputDecoration(
                      hintText: 'PT Audit Teknologi Indonesia',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                  _buildLabel('NIB', textTheme: textTheme),
                  ReactiveTextField(
                    formControlName: 'nib',
                    decoration: const InputDecoration(
                      hintText: '1234567890123',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                  _buildLabel('Bentuk Badan Hukum',
                      isRequired: false, textTheme: textTheme),
                  ReactiveDropdownField<String>(
                    formControlName: 'badan',
                    decoration: const InputDecoration(
                      hintText: 'Pilih Badan Hukum',
                      prefixIcon: Icon(Icons.apartment_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'PT', child: Text('PT')),
                      DropdownMenuItem(value: 'CV', child: Text('CV')),
                      DropdownMenuItem(
                          value: 'Yayasan', child: Text('Yayasan')),
                      DropdownMenuItem(
                          value: 'Koperasi', child: Text('Koperasi')),
                      DropdownMenuItem(
                          value: 'Lainnya', child: Text('Lainnya')),
                    ],
                  ),
                  _buildLabel('Provinsi', textTheme: textTheme),
                  ReactiveDropdownField<String>(
                    formControlName: 'provinsi',
                    decoration: const InputDecoration(
                      hintText: 'Pilih Provinsi',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    items: provinces
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                  ),
                  _buildLabel('Kota/Kabupaten', textTheme: textTheme),
                  ReactiveTextField(
                    formControlName: 'kota',
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Jakarta Pusat',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                  ),
                  _buildLabel('Alamat Lengkap', textTheme: textTheme),
                  ReactiveTextField(
                    formControlName: 'alamat',
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Alamat lengkap perusahaan',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  _buildLabel('Kode Pos',
                      isRequired: false, textTheme: textTheme),
                  ReactiveTextField(
                    formControlName: 'kodePos',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: 12345',
                      prefixIcon: Icon(Icons.mail_outlined),
                    ),
                  ),
                  _buildLabel('Nomor Telepon Lembaga', textTheme: textTheme),
                  ReactiveTextField(
                    formControlName: 'telepon',
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '021xxxxxx',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  _buildLabel('Email Resmi Lembaga', textTheme: textTheme),
                  ReactiveTextField(
                    formControlName: 'email',
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'email@lembaga.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  _buildLabel('Website Lengkap',
                      isRequired: false, textTheme: textTheme),
                  ReactiveTextField(
                    formControlName: 'website',
                    decoration: const InputDecoration(
                      hintText: 'https://...',
                      prefixIcon: Icon(Icons.language_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Usually goes back, but this is step 1. If we have step 0, go there.
                  },
                  child: const Text('Kembali'),
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    form.markAllAsTouched();
                    final kodePos =
                        form.control('kodePos').value?.toString() ?? '';
                    if (kDebugMode) {
                      final raw = form.rawValue;
                      debugPrint('=== STEP1 SUBMIT DEBUG ===');
                      debugPrint('form.invalid: ${form.invalid}');
                      debugPrint('rawValue: $raw');
                      for (final entry in form.controls.entries) {
                        final c = entry.value;
                        debugPrint(
                          '[${entry.key}] value="${c.value}" valid=${c.valid} invalid=${c.invalid} errors=${c.errors}',
                        );
                      }
                      debugPrint(
                        'custom nib validator: ${AppValidators.nib(form.control('nib').value?.toString())}',
                      );
                    }
                    if (form.invalid) {
                      _showErrorSnackBar(context, 'Lengkapi data yang wajib');
                      return;
                    }
                    if (AppValidators.nib(
                            form.control('nib').value?.toString()) !=
                        null) {
                      _showErrorSnackBar(context, 'NIB tidak valid');
                      return;
                    }
                    if (kodePos.isNotEmpty && kodePos.length < 5) {
                      _showErrorSnackBar(context, 'Kode pos minimal 5 digit');
                      return;
                    }
                    ref.read(registrasiProvider.notifier).setLembaga(
                          LembagaModel(
                            nama: form.control('nama').value,
                            nib: form.control('nib').value,
                            badanHukum: form.control('badan').value ?? '',
                            alamat: form.control('alamat').value,
                            provinsi: form.control('provinsi').value,
                            kota: form.control('kota').value,
                            kodePos: kodePos,
                            telepon: form.control('telepon').value,
                            email: form.control('email').value,
                            website: form.control('website').value ?? '',
                          ),
                        );
                    ref.read(registrasiProvider.notifier).setStep(1);
                  },
                  child: const Text('Selanjutnya'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text,
      {bool isRequired = true, TextTheme? textTheme}) {
    textTheme ??= Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppTheme.spacing12,
        top: AppTheme.spacing16,
      ),
      child: RichText(
        text: TextSpan(
          text: text,
          style: textTheme.labelLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          children: isRequired
              ? [
                  TextSpan(
                    text: ' *',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
