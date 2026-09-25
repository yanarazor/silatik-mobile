import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../data/models/latik_profile.dart';
import '../../data/models/notifikasi_model.dart';
import '../../providers/notifikasi_provider.dart';
import '../../providers/profile_menu_provider.dart';
import '../shared/blue_header_band.dart';
import 'widgets/error_card.dart';
import 'widgets/latik_summary_card.dart';
import 'widgets/loading_card.dart';
import 'widgets/quick_action.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(unreadNotificationProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    final latikAsync = ref.watch(latikProfileProvider);
    final latik = latikAsync.valueOrNull;
    final namaLatik =
        (latik?.namaLatik.isNotEmpty ?? false) ? latik!.namaLatik : 'LATIK';

    return Stack(
      children: [
        const BlueHeaderBand(height: 164),
        SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(latikProfileProvider);
              ref.invalidate(unreadNotificationProvider);
              ref.invalidate(unreadNotificationCountProvider);
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
                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            namaLatik,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xDDEAF2FF),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          context.go(AppRoutes.notifications),
                      icon: Badge(
                        isLabelVisible: (unreadCountAsync.valueOrNull ?? 0) >
                            0,
                        label: Text(
                          '${unreadCountAsync.valueOrNull ?? 0}',
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
                const SizedBox(height: 24),
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
                    const SizedBox(width: 18),
                    QuickAction(
                      icon: Icons.receipt_long_outlined,
                      label: 'Transaksi',
                      onTap: () => context.push(AppRoutes.transaksi),
                    ),
                    const SizedBox(width: 18),
                    QuickAction(
                      icon: Icons.autorenew_rounded,
                      label: 'Perpanjangan',
                      onTap: () => context.push(AppRoutes.perpanjangan),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'Notifikasi Terbaru',
                  style: TextStyle(
                    color: Color(0xFF0C2D5C),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                notifAsync.when(
                  data: (items) {
                    final latest = items.take(2).toList();
                    if (latest.isEmpty) {
                      return const Text('Belum ada notifikasi');
                    }
                    return Column(
                      children: latest.map((item) {
                        final isWarning =
                            item.kategori == 'Tindakan Diperlukan';
                        final actionUrl = item.actionUrl?.trim();
                        return InkWell(
                          onTap: actionUrl != null && actionUrl.isNotEmpty
                              ? () {
                                  final uri = Uri.tryParse(actionUrl);
                                  if (uri != null &&
                                      _invoiceRefFromUrl(uri) != null) {
                                    ref
                                        .read(notifikasiListProvider.notifier)
                                        .markAsRead(item.id);
                                  }
                                  _openAction(context, actionUrl);
                                }
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 11,
                                  height: 11,
                                  decoration: BoxDecoration(
                                    color: isWarning
                                        ? AppColors.accent
                                        : AppColors.primary,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.judul,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF1C2638),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (item.isi.trim().isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.isi,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF6B778C),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _timeAgo(item.waktu),
                                  style: const TextStyle(
                                    color: Color(0xFF8A96AA),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (actionUrl != null &&
                                    actionUrl.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.open_in_new,
                                      size: 14, color: AppColors.primary),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Gagal memuat notifikasi'),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.notifications),
                    child: const Text(
                      'Lihat semua notifikasi  >',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _timeAgo(DateTime waktu) {
    final d = DateTime.now().difference(waktu);
    if (d.inMinutes < 60) return '${d.inMinutes} mnt lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    return '${d.inDays} hari lalu';
  }

  static Future<void> _openAction(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final invoiceRef = _invoiceRefFromUrl(uri);
    if (invoiceRef != null) {
      context.push(
          '${AppRoutes.pdfViewer}?ref=${Uri.encodeQueryComponent(invoiceRef)}');
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String? _invoiceRefFromUrl(Uri uri) {
    final segments =
        uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
    for (var i = 0; i < segments.length; i++) {
      if ((segments[i] == 'invoice' || segments[i] == 'transaction') &&
          i + 1 < segments.length) {
        return segments[i + 1];
      }
    }
    return null;
  }
}