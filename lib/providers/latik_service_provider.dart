import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/latik_service.dart';
import 'auth_provider.dart';

final latikServiceProvider =
    Provider((ref) => LatikService(ref.watch(dioProvider)));