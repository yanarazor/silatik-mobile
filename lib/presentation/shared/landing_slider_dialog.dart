import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/slider.dart';
import '../../providers/slider_provider.dart';
import 'landing_slider_carousel.dart';

bool _shownThisLaunch = false;

Future<void> showLandingSliderDialog(BuildContext context, WidgetRef ref) async {
  if (_shownThisLaunch) return;
  final sliders = await ref
      .read(landingSlidersProvider.future)
      .catchError((_) => const <SliderItem>[]);
  if (!context.mounted) return;
  if (!sliders.any((s) => s.isAktif && s.srcUrl.isNotEmpty)) return;

  _shownThisLaunch = true;
  await showDialog<void>(
    context: context,
    builder: (_) => const _LandingSliderDialog(),
  );
}

class _LandingSliderDialog extends StatelessWidget {
  const _LandingSliderDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: LandingSliderCarousel(),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.45),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
