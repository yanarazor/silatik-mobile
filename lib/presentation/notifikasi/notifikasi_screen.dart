import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../data/models/notifikasi_model.dart';
import '../../providers/notifikasi_provider.dart';
import '../shared/blue_header_band.dart';
import '../shared/header_filter_pills.dart';
import '../shared/header_title.dart';

const _cardRadius = 16.0;
const _borderColor = Color(0xFFE2E8F0);
const _dividerColor = Color(0xFFF1F5F9);
const _iconSurface = Color(0xFFEBF3FA);
const _titleColor = Color(0xFF1A1A2E);
const _bodyColor = Color(0xFF475569);
const _mutedColor = Color(0xFF64748B);
const _timeColor = Color(0xFF94A3B8);
const _unreadDot = Color(0xFF2563EB);

class NotifikasiScreen extends ConsumerStatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  ConsumerState<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends ConsumerState<NotifikasiScreen> {
  NotifikasiSource _source = NotifikasiSource.all;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notifikasiListProvider.notifier).loadMore();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notifikasiListProvider.notifier).loadMore();
    }
  }

  void _setSource(NotifikasiSource value) {
    if (_source == value) return;
    ref.read(notifikasiListProvider.notifier).setSource(value);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    setState(() => _source = value);
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(notifikasiListProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider).valueOrNull;

    return Stack(
      children: [
        const BlueHeaderBand(height: 150),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeaderTitle(
                      title: 'Notifikasi',
                      subtitle: 'Kelola dan pantau pemberitahuan Anda',
                      trailing: IconButton(
                        onPressed: () => context.go(AppRoutes.dashboard),
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.white,
                        tooltip: 'Tutup',
                      ),
                    ),
                    const SizedBox(height: 14),
                    HeaderFilterPills<NotifikasiSource>(
                      selected: _source,
                      onSelected: _setSource,
                      options: [
                        // No badge on "Semua": the total across all pages is
                        // not exposed to this screen, and the fetched count
                        // would undercount.
                        const HeaderFilterOption(
                          value: NotifikasiSource.all,
                          label: 'Semua',
                        ),
                        HeaderFilterOption(
                          value: NotifikasiSource.unread,
                          label: 'Belum Dibaca',
                          count: unreadCount,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: listState.isLoading && listState.items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : listState.error != null && listState.items.isEmpty
                        ? _ErrorRetry(
                            onRetry: () => ref
                                .read(notifikasiListProvider.notifier)
                                .refresh(),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              await ref
                                  .read(notifikasiListProvider.notifier)
                                  .refresh();
                              ref.invalidate(unreadNotificationCountProvider);
                            },
                            child: _buildList(listState),
                          ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(NotifikasiListState listState) {
    final items = listState.items;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _autoLoadMoreIfNeeded(listState));
    final itemCount =
        items.isEmpty ? 1 : items.length + (listState.hasMore ? 1 : 0);

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        if (index < items.length) return _NotificationCard(item: items[index]);
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 56),
            child: Center(
              child: listState.hasMore
                  ? const CircularProgressIndicator()
                  : Text(
                      _source == NotifikasiSource.unread
                          ? 'Semua notifikasi sudah dibaca.'
                          : 'Belum ada notifikasi.',
                      style: const TextStyle(
                        color: _mutedColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          );
        }
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        );
      },
    );
  }

  void _autoLoadMoreIfNeeded(NotifikasiListState listState) {
    if (!mounted || !listState.hasMore) return;
    if (listState.isLoading || listState.isLoadingMore) return;
    final position =
        _scrollController.hasClients ? _scrollController.position : null;
    final fillsViewport = position != null && position.maxScrollExtent > 0;
    if (!fillsViewport) {
      ref.read(notifikasiListProvider.notifier).loadMore();
    }
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.item});

  final NotifikasiModel item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = !item.isRead;
    final hasAction = (item.actionUrl ?? '').trim().isNotEmpty;

    return Material(
      // Read cards sit slightly translucent over the page background so they
      // recede without introducing a second surface color.
      color: unread ? Colors.white : Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(_cardRadius),
      elevation: unread ? 1.5 : 0,
      shadowColor: const Color(0x140B2D5C),
      child: InkWell(
        onTap: () => _handleTap(context, ref),
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_cardRadius),
            border: Border.all(
              color:
                  unread ? _borderColor : _borderColor.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _iconSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      size: 21,
                      color: unread
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timestamp and unread dot ride the title's first line
                        // and end flush with the card edge. The title is the
                        // flexible half, so a long absolute date truncates the
                        // title instead of overlapping it.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.judul,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: unread ? _titleColor : _bodyColor,
                                  fontSize: 14,
                                  height: 1.3,
                                  fontWeight: unread
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Padding(
                              // Nudges the 11px label onto the title's cap line.
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  Text(
                                    _timeAgo(item.waktu),
                                    style: const TextStyle(
                                      color: _timeColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (unread) ...[
                                    const SizedBox(width: 6),
                                    Semantics(
                                      label: 'Belum dibaca',
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFEFF6FF),
                                        ),
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _unreadDot,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (item.isi.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.isi,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unread ? _bodyColor : _mutedColor,
                              fontSize: 12.5,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (hasAction) ...[
                const SizedBox(height: 14),
                const Divider(height: 1, thickness: 1, color: _dividerColor),
                const SizedBox(height: 11),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Buka',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.open_in_new_rounded,
                        size: 15, color: AppColors.primary),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime waktu) {
    final d = DateTime.now().difference(waktu);
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    if (d.inDays == 1) return 'Kemarin';
    return DateFormat('MMM d, yyyy h:mm a').format(waktu);
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    if (!item.isRead) {
      ref.read(notifikasiListProvider.notifier).markAsRead(item.id);
    }

    final uri = Uri.tryParse((item.actionUrl ?? '').trim());
    if (uri == null || uri.toString().isEmpty) return;

    final invoiceRef = _invoiceRefFromUrl(uri);
    if (invoiceRef != null) {
      context.push(
          '${AppRoutes.pdfViewer}?ref=${Uri.encodeQueryComponent(invoiceRef)}');
      return;
    }

    // Relative or schemeless action URLs cannot be launched externally.
    if (!uri.hasScheme) return;
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }

  String? _invoiceRefFromUrl(Uri uri) {
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

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Gagal memuat notifikasi',
            style: TextStyle(
              color: _titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}
