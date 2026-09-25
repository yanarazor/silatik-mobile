import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/profile_menu_provider.dart';
import 'widgets/berkas/docs_view.dart';

class DokumenBerkasScreen extends ConsumerWidget {
  const DokumenBerkasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(dokumenBerkasProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dokumen & Berkas'),
      ),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Gagal memuat dokumen.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(dokumenBerkasProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (docs) => DocsView(docs: docs),
      ),
      bottomNavigationBar: docsAsync.hasValue
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.dokumenBerkasEdit),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Dokumen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}