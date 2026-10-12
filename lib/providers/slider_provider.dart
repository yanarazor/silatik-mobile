import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/slider.dart';
import '../data/services/slider_service.dart';
import 'auth_provider.dart';

final sliderServiceProvider =
    Provider((ref) => SliderService(ref.watch(dioProvider)));

final landingSlidersProvider =
    FutureProvider.autoDispose<List<SliderItem>>((ref) {
  return ref.watch(sliderServiceProvider).getLandingSliders();
});
