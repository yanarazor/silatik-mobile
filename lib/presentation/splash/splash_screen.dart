import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/utils/url_opener.dart';
import '../../data/services/force_update_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/force_update_provider.dart';
import '../shared/force_update_dialog.dart';

/// First route: restores the session, then routes to dashboard or login.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _bootstrapAuth();
  }

  Future<void> _bootstrapAuth() async {
    final update = await _checkForceUpdate();
    if (!mounted) return;
    if (update.updateAvailable) {
      await _showForceUpdateDialog(update);
      if (!mounted) return;
      if (update.forceUpdate) return;
    }

    await ref.read(authProvider.notifier).checkAuth();
    if (!mounted) return;
    _redirectTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final isLoggedIn = ref.read(authProvider).isLoggedIn;
      context.go(isLoggedIn ? AppRoutes.dashboard : AppRoutes.login);
    });
  }

  Future<ForceUpdateInfo> _checkForceUpdate() async {
    try {
      return await ref.read(forceUpdateCheckProvider.future);
    } catch (_) {
      return const ForceUpdateInfo(
        updateAvailable: false,
        forceUpdate: false,
        latestVersion: '',
        updateUrl: '',
      );
    }
  }

  Future<void> _showForceUpdateDialog(ForceUpdateInfo info) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (ctx) => ForceUpdateDialog(
        latestVersion: info.latestVersion,
        force: info.forceUpdate,
        onUpdatePressed: () {
          if (info.updateUrl.isNotEmpty) {
            openFileUrl(context, info.updateUrl,
                failureMessage: 'Gagal membuka halaman pembaruan');
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7FAFE),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF003D7A),
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: Icon(Icons.account_balance_outlined,
                      color: Colors.white, size: 42),
                ),
              ),
              SizedBox(height: 22),
              Text(
                'SILATIK',
                style: TextStyle(
                  color: Color(0xFF003D7A),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Sistem Informasi LATIK - BRIN',
                style: TextStyle(
                  color: Color(0xFF6E7B91),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 70),
              SizedBox(
                width: 74,
                child: LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: Color(0xFFE4ECF7),
                  color: Color(0xFFFFB51B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}