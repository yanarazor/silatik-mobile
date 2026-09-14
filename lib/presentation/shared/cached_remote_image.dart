import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedRemoteImage extends StatelessWidget {
  const CachedRemoteImage({
    super.key,
    required this.url,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String url;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url.trim(),
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => Center(child: fallback),
      errorWidget: (_, __, ___) => Center(child: fallback),
    );
  }
}
