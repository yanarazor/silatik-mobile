import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final password = TextEditingController();
    final confirmPassword = TextEditingController();
    final state = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.error != null) {
        _showErrorSnackBar(context, next.error!);
      } else if (!next.isLoading && prev?.isLoading == true) {
        context.push(AppRoutes.activationNotice);
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAFE),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Daftar Akun',
                      style: TextStyle(
                        color: Color(0xFF0C2D5C),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Input(
                  label: 'Nama PIC',
                  hint: 'Nama Penanggung Jawab',
                  controller: name),
              _Input(
                  label: 'Email',
                  hint: 'email@lembaga.com',
                  controller: email,
                  keyboardType: TextInputType.emailAddress),
              _Input(
                  label: 'No. HP',
                  hint: '08xxxxxxxxxx',
                  controller: phone,
                  keyboardType: TextInputType.phone),
              _Input(
                  label: 'Password',
                  hint: 'Min. 8 karakter',
                  controller: password,
                  obscureText: true),
              _Input(
                  label: 'Konfirmasi Password',
                  hint: 'Ulangi password',
                  controller: confirmPassword,
                  obscureText: true),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        if (password.text != confirmPassword.text) {
                          _showErrorSnackBar(context, 'Password tidak cocok');
                          return;
                        }
                        if (name.text.isEmpty ||
                            email.text.isEmpty ||
                            phone.text.isEmpty ||
                            password.text.isEmpty) {
                          _showErrorSnackBar(
                              context, 'Semua field harus diisi');
                          return;
                        }
                        ref.read(authProvider.notifier).register({
                          'nama': name.text,
                          'email': email.text,
                          'phone': phone.text,
                          'password': password.text,
                        });
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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

class _Input extends StatelessWidget {
  const _Input({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF243552),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}
