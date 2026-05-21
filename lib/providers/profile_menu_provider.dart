import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/profile_menu_service.dart';
import 'auth_provider.dart';

final profileMenuServiceProvider = Provider((ref) => ProfileMenuService(ref.watch(dioProvider)));

final latikProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  final user = ref.watch(authProvider).user;
  final latikRef = user?['latik_ref']?.toString();
  return ref.watch(profileMenuServiceProvider).getLatikProfile(latikRef: latikRef);
});

final userProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(profileMenuServiceProvider).getUserProfile();
});

final faqProfileProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(profileMenuServiceProvider).getFaqs();
});
