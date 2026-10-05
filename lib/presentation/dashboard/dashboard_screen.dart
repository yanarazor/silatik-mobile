import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../data/models/latik_profile.dart';
import '../../data/models/notifikasi_model.dart';
import '../../providers/auditor_provider.dart';
import '../../providers/notifikasi_provider.dart';
import '../../providers/profile_menu_provider.dart';
import '../notifikasi/widgets/notification_card.dart';
import '../shared/blue_header_band.dart';
import '../shared/error_retry.dart';
import 'widgets/auditor_summary_section.dart';
import 'widgets/error_card.dart';
import 'widgets/latik_summary_card.dart';
import 'widgets/loading_card.dart';
import 'widgets/quick_action.dart';
import 'widgets/str_validity_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latikAsync = ref.watch(latikProfileProvider);
    final notifAsync = ref.watch(unreadNotificationProvider);
    final unreadCount =
        ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;

    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? 'Selamat pagi,'
        : hour < 15
            ? 'Selamat siang,'
            : hour < 18
                ? 'Selamat sore,'
                : 'Selamat malam,';
    final namaLatik = (latikAsync.valueOrNull?.namaLatik.isNotEmpty ?? false)
        ? latikAsync.valueOrNull!.namaLatik
        : 'LATIK';

    return Stack(
      children: [
        const BlueHeaderBand(height: 164),
        SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(latikProfileProvider);
              ref.invalidate(unreadNotificationProvider);
              ref.invalidate(unreadNotificationCountProvider);
              ref.invalidate(auditorListProvider);
              await Future.wait([
                ref
                    .read(latikProfileProvider.future)
                    .catchError((_) => const LatikProfile()),
                ref
                    .read(unreadNotificationProvider.future)
                    .catchError((_) => <NotifikasiModel>[]),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: const TextStyle(
                              color: Color(0xD1EAF2FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            namaLatik,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.go(AppRoutes.notifications),
                      icon: Badge(
                        isLabelVisible: unreadCount > 0,
                        label: Text(
                          '$unreadCount',
                          style: const TextStyle(fontSize: 10),
                        ),
                        child: const Icon(Icons.notifications_rounded,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                latikAsync.when(
                  data: (data) => LatikSummaryCard(data: data),
                  loading: () => const LoadingCard(),
                  error: (_, __) => ErrorCard(
                    onRetry: () => ref.invalidate(latikProfileProvider),
                  ),
                ),
                const SizedBox(height: 16),
                latikAsync.when(
                  data: (data) => StrValidityCard(
                    strTanggalAkhir: data.strTanggalAkhir,
                    fileUrl: data.fileStr,
                  ),
                  loading: () => const _StrValiditySkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _sectionDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aksi Cepat',
                        style: TextStyle(
                          color: Color(0xFF0C2D5C),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          QuickAction(
                            icon: Icons.description_outlined,
                            label: 'Dokumen',
                            onTap: () => context.push(AppRoutes.dokumen),
                          ),
                          const SizedBox(width: 12),
                          QuickAction(
                            icon: Icons.receipt_long_outlined,
                            label: 'Transaksi',
                            onTap: () => context.push(AppRoutes.transaksi),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          QuickAction(
                            icon: Icons.edit_note_rounded,
                            label: 'Revisi Ajuan',
                            onTap: () => context.push(AppRoutes.revisiEntry),
                          ),
                          const SizedBox(width: 12),
                          QuickAction(
                            icon: Icons.autorenew_rounded,
                            label: 'Perpanjangan',
                            onTap: () => context.push(AppRoutes.perpanjangan),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const AuditorSummarySection(),
                ..._buildNotificationSection(context, notifAsync, ref),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildNotificationSection(
    BuildContext context,
    AsyncValue<List<NotifikasiModel>> notifAsync,
    WidgetRef ref,
  ) {
    return notifAsync.when(
      data: (items) {
        final latest = items.take(3).toList();
        if (latest.isEmpty) return [];
        return [
          const SizedBox(height: 28),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Notifikasi Terbaru',
                  style: TextStyle(
                    color: Color(0xFF0C2D5C),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.notifications),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Lihat semua ›',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < latest.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            NotificationCard(item: latest[i]),
          ],
        ];
      },
      loading: () => [
        const SizedBox(height: 28),
        const _NotificationSkeletonList(),
      ],
      error: (_, __) => [
        const SizedBox(height: 28),
        ErrorRetry(
          message: 'Gagal memuat notifikasi.',
          onRetry: () => ref.invalidate(unreadNotificationProvider),
        ),
      ],
    );
  }
}

BoxDecoration _sectionDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE4ECF7)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0B2D5C).withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );

class _StrValiditySkeleton extends StatelessWidget {
  const _StrValiditySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: const Color(0xFFEDF1F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4ECF7)),
      ),
    );
  }
}

class _NotificationSkeletonList extends StatelessWidget {
  const _NotificationSkeletonList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Container(
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF1F7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4ECF7)),
            ),
          ),
        ],
      ],
    );
  }
}
