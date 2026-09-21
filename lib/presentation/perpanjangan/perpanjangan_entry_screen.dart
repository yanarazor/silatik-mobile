import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/latik_ext_model.dart';
import '../../providers/auditor_ext_provider.dart';
import '../../providers/latik_ext_provider.dart';

class PerpanjanganEntryScreen extends ConsumerStatefulWidget {
  const PerpanjanganEntryScreen({super.key});

  @override
  ConsumerState<PerpanjanganEntryScreen> createState() =>
      _PerpanjanganEntryScreenState();
}

class _PerpanjanganEntryScreenState
    extends ConsumerState<PerpanjanganEntryScreen> {
  bool _busy = false;

  Future<void> _startLatik() => _start(
        confirmTitle: 'Perpanjang Registrasi LATIK',
        confirmMessage: 'Anda yakin ingin memperpanjang registrasi lembaga?',
        route: AppRoutes.perpanjanganLatik,
        resolve: () {
          ref.invalidate(latikExtResolveProvider);
          return ref.read(latikExtResolveProvider.future);
        },
      );

  Future<void> _startAuditor() => _start(
        confirmTitle: 'Perpanjang Registrasi Auditor',
        confirmMessage: 'Anda yakin ingin memperpanjang registrasi auditor?',
        route: AppRoutes.perpanjanganAuditor,
        resolve: () {
          ref.invalidate(auditorExtResolveProvider);
          return ref.read(auditorExtResolveProvider.future);
        },
      );

  Future<void> _start({
    required String confirmTitle,
    required String confirmMessage,
    required String route,
    required Future<ExtResolution?> Function() resolve,
  }) async {
    final confirmed = await _confirm(confirmTitle, confirmMessage);
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    ExtResolution? resolution;
    String? error;
    try {
      resolution = await resolve();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;

    if (error != null) {
      _info('Gagal', 'Tidak dapat memulai perpanjangan.\n$error');
      return;
    }
    if (resolution == null) {
      _info('Tidak tersedia',
          'Perpanjangan belum dapat dimulai saat ini.');
      return;
    }

    switch (resolution.action) {
      case ExtAction.proceed:
        context.push(route, extra: resolution.refExt);
      case ExtAction.inVerification:
        _info('Sedang Diverifikasi',
            'Pengajuan perpanjangan Anda sedang dalam proses verifikasi.');
      case ExtAction.publishingStr:
        _info('Proses Penerbitan STR',
            'Pengajuan Anda sedang dalam proses penerbitan STR.');
      case ExtAction.returned:
        _info(
          'Pengajuan Dikembalikan',
          'Pengajuan perpanjangan Anda dikembalikan untuk perbaikan. '
              'Silakan lakukan perbaikan melalui aplikasi web.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Perpanjangan Registrasi',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                Text(
                  'Pilih jenis registrasi yang ingin diperpanjang.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppTheme.spacing16),
                _ChoiceCard(
                  icon: Icons.business_rounded,
                  title: 'Lembaga (LATIK)',
                  subtitle: 'Perpanjang registrasi institusi.',
                  enabled: !_busy,
                  onTap: _startLatik,
                ),
                const SizedBox(height: AppTheme.spacing12),
                _ChoiceCard(
                  icon: Icons.groups_rounded,
                  title: 'Auditor',
                  subtitle: 'Perpanjang registrasi satu atau lebih auditor.',
                  enabled: !_busy,
                  onTap: _startAuditor,
                ),
              ],
            ),
            if (_busy)
              const ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirm(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Lanjutkan'),
          ),
        ],
      ),
    );
  }

  void _info(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
