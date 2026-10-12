import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/slider_provider.dart';

const double _kSliderAspectRatio = 1080 / 720;

class LandingSliderCarousel extends ConsumerStatefulWidget {
  const LandingSliderCarousel({
    super.key,
    this.interval = const Duration(seconds: 4),
  });

  final Duration interval;

  @override
  ConsumerState<LandingSliderCarousel> createState() =>
      _LandingSliderCarouselState();
}

class _LandingSliderCarouselState extends ConsumerState<LandingSliderCarousel> {
  final _pageController = PageController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer(int itemCount) {
    _timer?.cancel();
    if (itemCount < 2) return;
    _timer = Timer.periodic(widget.interval, (_) {
      final next = ((_pageController.page ?? 0).round() + 1) % itemCount;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final slidersAsync = ref.watch(landingSlidersProvider);

    return slidersAsync.when(
      loading: () => const _Frame(
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => _Frame(
        child: Center(
          child: IconButton(
            tooltip: 'Coba lagi',
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: () => ref.invalidate(landingSlidersProvider),
          ),
        ),
      ),
      data: (sliders) {
        final active =
            sliders.where((s) => s.isAktif && s.srcUrl.isNotEmpty).toList();
        if (active.isEmpty) return const SizedBox.shrink();
        _startTimer(active.length);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Frame(
              child: PageView.builder(
                controller: _pageController,
                itemCount: active.length,
                itemBuilder: (context, index) {
                  final item = active[index];
                  return CachedNetworkImage(
                    key: ValueKey(item.id),
                    imageUrl: item.srcUrl,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 200),
                    placeholder: (_, __) =>
                        const ColoredBox(color: Color(0xFFE8EEF6)),
                    errorWidget: (_, __, ___) => const ColoredBox(
                      color: Color(0xFFE8EEF6),
                      child: Icon(Icons.image_not_supported_outlined,
                          color: Color(0xFF9FB0C6)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _Dots(controller: _pageController, count: active.length),
          ],
        );
      },
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _kSliderAspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(color: const Color(0xFFE8EEF6), child: child),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.controller, required this.count});

  final PageController controller;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final current =
                (controller.hasClients ? controller.page : 0)?.round() ?? 0;
            final isActive = current == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : const Color(0xFFCBD8E8),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          },
        );
      }),
    );
  }
}
