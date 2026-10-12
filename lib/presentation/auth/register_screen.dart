import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/enums.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../shared/date_field.dart';
import '../shared/field_label.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late final FormGroup form;
  StreamSubscription<dynamic>? _passwordSub;
  DateTime? _birthDate;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    form = FormGroup({
      'nama_lengkap': FormControl<String>(validators: [Validators.required]),
      'email': FormControl<String>(
          validators: [Validators.required, Validators.email]),
      'jenis_identitas': FormControl<String>(validators: [Validators.required]),
      'nomor_identitas': FormControl<String>(validators: [Validators.required]),
      'jenis_kelamin': FormControl<String>(validators: [Validators.required]),
      'password': FormControl<String>(validators: [Validators.required]),
      'konfirmasi_password':
          FormControl<String>(validators: [Validators.required]),
    });

    _passwordSub = form.control('password').valueChanges.listen((_) {
      if (form.control('konfirmasi_password').touched) {
        form.control('konfirmasi_password').updateValueAndValidity();
      }
    });
  }

  @override
  void dispose() {
    _passwordSub?.cancel();
    form.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _submit() async {
    form.markAllAsTouched();
    if (form.invalid) {
      _showErrorSnackBar('Lengkapi data wajib dengan benar');
      return;
    }

    final password = form.control('password').value as String? ?? '';
    final passwordError = AppValidators.password(password);
    if (passwordError != null) {
      _showErrorSnackBar(passwordError);
      return;
    }

    final confirm =
        form.control('konfirmasi_password').value as String? ?? '';
    final confirmError = AppValidators.confirmPassword(confirm, password);
    if (confirmError != null) {
      _showErrorSnackBar(confirmError);
      return;
    }

    if (_birthDate == null) {
      _showErrorSnackBar('Tanggal lahir wajib diisi');
      return;
    }

    final payload = <String, dynamic>{
      'nama_lengkap':
          (form.control('nama_lengkap').value as String? ?? '').trim(),
      'email': (form.control('email').value as String? ?? '').trim(),
      'password': password,
      'konfirmasi_password': confirm,
      'jenis_identitas':
          form.control('jenis_identitas').value as String? ?? '',
      'nomor_identitas':
          (form.control('nomor_identitas').value as String? ?? '').trim(),
      'jenis_kelamin': form.control('jenis_kelamin').value as String? ?? '',
      'birth_data': _birthDate!.toIso8601String().split('T').first,
    };

    try {
      await ref.read(authProvider.notifier).register(payload);
    } catch (_) {
      // Pesan sudah ditampilkan lewat ref.listen(authProvider).
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.error != null) {
        _showErrorSnackBar(next.error!);
      } else if (!next.isLoading && prev?.isLoading == true) {
        if (mounted) context.push(AppRoutes.activationNotice);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Daftar Akun'),
      ),
      body: SafeArea(
        child: ReactiveForm(
          formGroup: form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            children: [
              const FieldLabel('Nama Lengkap'),
              ReactiveTextField<String>(
                formControlName: 'nama_lengkap',
                textInputAction: TextInputAction.next,
                validationMessages: {
                  ValidationMessage.required: (_) => 'Nama lengkap wajib diisi',
                },
                decoration: const InputDecoration(
                  hintText: 'Nama Penanggung Jawab',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const FieldLabel('Email'),
              ReactiveTextField<String>(
                formControlName: 'email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validationMessages: {
                  ValidationMessage.required: (_) => 'Email wajib diisi',
                  ValidationMessage.email: (_) => 'Format email tidak valid',
                },
                decoration: const InputDecoration(
                  hintText: 'email@lembaga.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const FieldLabel('Jenis Identitas'),
              ReactiveDropdownField<String>(
                formControlName: 'jenis_identitas',
                isExpanded: true,
                validationMessages: {
                  ValidationMessage.required: (_) =>
                      'Jenis identitas wajib dipilih',
                },
                decoration: const InputDecoration(
                  hintText: 'Pilih Jenis Identitas',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: [
                  for (final e in IdentityType.values)
                    DropdownMenuItem(value: e.value, child: Text(e.label)),
                ],
              ),
              const FieldLabel('Nomor Identitas'),
              ReactiveTextField<String>(
                formControlName: 'nomor_identitas',
                textInputAction: TextInputAction.next,
                validationMessages: {
                  ValidationMessage.required: (_) =>
                      'Nomor identitas wajib diisi',
                },
                decoration: const InputDecoration(
                  hintText: 'Nomor sesuai identitas',
                  prefixIcon: Icon(Icons.credit_card_outlined),
                ),
              ),
              const FieldLabel('Jenis Kelamin'),
              ReactiveDropdownField<String>(
                formControlName: 'jenis_kelamin',
                isExpanded: true,
                validationMessages: {
                  ValidationMessage.required: (_) =>
                      'Jenis kelamin wajib dipilih',
                },
                decoration: const InputDecoration(
                  hintText: 'Pilih Jenis Kelamin',
                  prefixIcon: Icon(Icons.wc_outlined),
                ),
                items: [
                  for (final g in Gender.values)
                    DropdownMenuItem(value: g.value, child: Text(g.label)),
                ],
              ),
              const FieldLabel('Tanggal Lahir'),
              DateField(
                value: _birthDate,
                hint: 'Pilih tanggal lahir',
                onPick: (d) => setState(() => _birthDate = d),
              ),
              const FieldLabel('Password'),
              ReactiveTextField<String>(
                formControlName: 'password',
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                validationMessages: {
                  ValidationMessage.required: (_) => 'Password wajib diisi',
                },
                decoration: InputDecoration(
                  hintText: 'Min. 8 karakter, huruf besar/kecil, angka, simbol',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const FieldLabel('Konfirmasi Password'),
              ReactiveTextField<String>(
                formControlName: 'konfirmasi_password',
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!state.isLoading) _submit();
                },
                validationMessages: {
                  ValidationMessage.required: (_) =>
                      'Konfirmasi password wajib diisi',
                },
                decoration: InputDecoration(
                  hintText: 'Ulangi password',
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: state.isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Daftar',
                        style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
