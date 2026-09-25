import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../providers/notifikasi_provider.dart';
import '../shared/blue_header_band.dart';
import '../shared/error_retry.dart';
import '../shared/header_filter_pills.dart';
import '../shared/header_title.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_colors.dart';

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
                        ? ErrorRetry(
                            message: 'Gagal memuat notifikasi',
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
        if (index < items.length) {
          return NotificationCard(item: items[index]);
        }
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
                        color: notifMutedColor,
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