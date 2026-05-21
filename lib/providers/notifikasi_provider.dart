import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/notifikasi_model.dart';
import '../data/repositories/notifikasi_repository.dart';
import '../data/services/notifikasi_service.dart';
import 'auth_provider.dart';

final notifikasiServiceProvider = Provider((ref) => NotifikasiService(ref.watch(dioProvider)));
final notifikasiRepoProvider = Provider((ref) => NotifikasiRepository(ref.watch(notifikasiServiceProvider)));
final notifikasiProvider = FutureProvider<List<NotifikasiModel>>((ref) => ref.watch(notifikasiRepoProvider).getList());
final unreadNotificationCountProvider = FutureProvider<int>((ref) => ref.watch(notifikasiRepoProvider).getUnreadCount());
