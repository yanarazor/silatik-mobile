import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/faq.dart';
import '../data/models/latik_profile.dart';
import '../data/models/user_profile.dart';
import '../data/services/profile_menu_service.dart';
import 'auth_provider.dart';

final profileMenuServiceProvider = Provider((ref) => ProfileMenuService(ref.watch(dioProvider)));

final latikProfileProvider = FutureProvider.autoDispose<LatikProfile>((ref) {
  final user = ref.watch(authProvider).user;
  final latikRef = user?['latik_ref']?.toString();
  return ref.watch(profileMenuServiceProvider).getLatikProfile(latikRef: latikRef);
});

final userProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) {
  return ref.watch(profileMenuServiceProvider).getUserProfile();
});

final faqProfileProvider = FutureProvider.autoDispose<List<Faq>>((ref) {
  return ref.watch(profileMenuServiceProvider).getFaqs();
});
