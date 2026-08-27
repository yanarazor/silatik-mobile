import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/notifikasi_model.dart';
import '../data/repositories/notifikasi_repository.dart';
import '../data/services/notifikasi_service.dart';
import 'auth_provider.dart';

final notifikasiServiceProvider =
    Provider((ref) => NotifikasiService(ref.watch(dioProvider)));
final notifikasiRepoProvider =
    Provider((ref) => NotifikasiRepository(ref.watch(notifikasiServiceProvider)));

final unreadNotificationCountProvider = FutureProvider<int>(
    (ref) => ref.watch(notifikasiRepoProvider).getUnreadCount());

final unreadNotificationProvider = FutureProvider<List<NotifikasiModel>>(
  (ref) async =>
      (await ref.watch(notifikasiRepoProvider).getUnreadPage()).items,
);

enum NotifikasiSource { all, unread }

class NotifikasiListState {
  const NotifikasiListState({
    this.items = const [],
    this.page = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<NotifikasiModel> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  NotifikasiListState copyWith({
    List<NotifikasiModel>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return NotifikasiListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotifikasiListNotifier extends Notifier<NotifikasiListState> {
  NotifikasiSource _source = NotifikasiSource.all;

  @override
  NotifikasiListState build() => const NotifikasiListState();

  void setSource(NotifikasiSource source) {
    if (source == _source && state.items.isNotEmpty) return;
    _source = source;
    state = const NotifikasiListState();
    loadMore();
  }

  Future<void> loadMore() async {
    final current = state;
    if (current.isLoading || current.isLoadingMore || !current.hasMore) return;
    final nextPage = current.page + 1;
    state = current.copyWith(
      isLoading: current.page == 0,
      isLoadingMore: current.page > 0,
    );
    try {
      final repo = ref.read(notifikasiRepoProvider);
      final result = _source == NotifikasiSource.all
          ? await repo.getPage(page: nextPage)
          : await repo.getUnreadPage(page: nextPage);
      state = state.copyWith(
        items: [...state.items, ...result.items],
        page: nextPage,
        hasMore: nextPage < result.totalPages,
        isLoading: false,
        isLoadingMore: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, isLoadingMore: false, error: e);
    }
  }

  Future<void> refresh() async {
    state = const NotifikasiListState();
    await loadMore();
  }

  Future<void> markAsRead(String refId) async {
    try {
      await ref.read(notifikasiRepoProvider).markAsRead(refId);
      if (_source == NotifikasiSource.unread) {
        state = state.copyWith(
          items: state.items.where((item) => item.id != refId).toList(),
        );
      }
      ref.invalidate(unreadNotificationCountProvider);
      ref.invalidate(unreadNotificationProvider);
    } catch (_) {
      // non-fatal: never block navigation when read-marking fails
    }
  }
}

final notifikasiListProvider =
    NotifierProvider<NotifikasiListNotifier, NotifikasiListState>(
        NotifikasiListNotifier.new);
