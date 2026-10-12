import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/force_update_service.dart';

final forceUpdateServiceProvider =
    Provider((ref) => ForceUpdateService());

final forceUpdateCheckProvider = FutureProvider<ForceUpdateInfo>((ref) {
  return ref.watch(forceUpdateServiceProvider).check();
});
