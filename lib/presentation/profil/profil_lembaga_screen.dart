import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auditor_provider.dart';
import '../../providers/profile_menu_provider.dart';
import '../shared/latik_info_section.dart';
import '../shared/latik_location_card.dart';
import 'widgets/lembaga/edit_footer.dart';
import 'widgets/lembaga/empty_profile_state.dart';
import 'widgets/lembaga/identity_card.dart';
import 'widgets/lembaga/stats_row.dart';

class ProfilLembagaScreen extends ConsumerWidget {
  const ProfilLembagaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(latikProfileProvider);
    final auditorCount =
        ref.watch(auditorListProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Profil Lembaga'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Gagal memuat data profil.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(latikProfileProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (data) {
          if (data.isEmpty) {
            return EmptyProfileState(
              onRetry: () => ref.invalidate(latikProfileProvider),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              IdentityCard(data: data),
              const SizedBox(height: 12),
              StatsRow(data: data, auditorCount: auditorCount),
              const SizedBox(height: 16),
              LatikInfoSection(data: data),
              if (LatikLocationCard.maybeBuild(data) case final map?) ...[
                const SizedBox(height: 16),
                map,
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: profileAsync.maybeWhen(
        data: (data) => EditFooter(
          onEdit: () =>
              context.push(AppRoutes.profilLembagaEdit, extra: data),
        ),
        orElse: () => null,
      ),
    );
  }
}