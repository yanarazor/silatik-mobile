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

class NotifikasiScreen extends ConsumerStatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  ConsumerState<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends ConsumerState<NotifikasiScreen> {
  String filter = 'Semua';
  final _scrollController = ScrollController();

  static const _filters = ['Semua', 'Belum Dibaca', 'Info'];

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

  void _setFilter(String value) {
    if (filter == value) return;
    ref.read(notifikasiListProvider.notifier).setSource(_sourceFor(value));
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    setState(() => filter = value);
  }

  NotifikasiSource _sourceFor(String value) =>
      value == 'Belum Dibaca' ? NotifikasiSource.unread : NotifikasiSource.all;

  List<NotifikasiModel> _filteredItems(List<NotifikasiModel> items) {
    if (filter == 'Info') {
      return items.where((item) => item.kategori == 'Info').toList();
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(notifikasiListProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);

    return Stack(
      children: [
        const BlueHeaderBand(height: 140),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifikasi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Kelola notifikasi Anda',
                            style: TextStyle(
                              color: Color(0xDDEAF2FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.go(AppRoutes.dashboard),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final item = _filters[index];
                    final selected = filter == item;
                    final label = item == 'Belum Dibaca' &&
                            unreadCountAsync.valueOrNull != null
                        ? 'Belum Dibaca (${unreadCountAsync.valueOrNull})'
                        : item;
                    return ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => _setFilter(item),
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF243552),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFFE4ECF7),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
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
    final items = _filteredItems(listState.items);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _autoLoadMoreIfNeeded(listState));
    final itemCount =
        items.isEmpty ? 1 : items.length + (listState.hasMore ? 1 : 0);

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 120),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        if (index < items.length) return _NotificationCard(item: items[index]);
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: listState.hasMore
                  ? const CircularProgressIndicator()
                  : const Text('Belum ada notifikasi untuk filter ini.'),
            ),
          );
        }
        return const SizedBox(height: 8);
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
    final color = item.kategori == 'Tindakan Diperlukan'
        ? AppColors.accent
        : (item.kategori == 'Info' ? AppColors.primary : AppColors.success);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4ECF7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2D5C).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.kategori == 'Tindakan Diperlukan'
                  ? Icons.assignment_late_outlined
                  : (item.kategori == 'Info'
                      ? Icons.info_outline_rounded
                      : Icons.description_outlined),
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.judul,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1C2638),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      _timeAgo(item.waktu),
                      style: const TextStyle(
                        color: Color(0xFF8A96AA),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item.isi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF5B6880),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                if (item.actionUrl != null && item.actionUrl!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _openAction(context, ref, item),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Buka'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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

  Future<void> _openAction(
      BuildContext context, WidgetRef ref, NotifikasiModel item) async {
    final url = item.actionUrl ?? '';
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final invoiceRef = _invoiceRefFromUrl(uri);
    if (invoiceRef != null) {
      ref.read(notifikasiListProvider.notifier).markAsRead(item.id);
      context.push(
          '${AppRoutes.pdfViewer}?ref=${Uri.encodeQueryComponent(invoiceRef)}');
      return;
    }

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
              color: Color(0xFF1C2638),
              fontSize: 14,
              fontWeight: FontWeight.w900,
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
