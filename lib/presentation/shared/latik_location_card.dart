import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/map_config.dart';
import '../../core/utils/url_opener.dart';
import '../../data/models/latik_profile.dart';
import 'widgets/latik_info_parts.dart';

/// Kartu "Lokasi Lembaga" — peta statis dari koordinat profil. Tap membuka
/// peta penuh di aplikasi peta. Kembalikan null (via [maybeBuild]) bila
/// koordinat tak valid.
class LatikLocationCard extends StatelessWidget {
  const LatikLocationCard._({required this.coord});

  final LatLng coord;

  /// Bangun kartu hanya bila koordinat valid; selain itu null.
  static Widget? maybeBuild(LatikProfile data) {
    final c = _parseLatLng(data.latitude, data.longitude);
    if (c == null) return null;
    return LatikLocationCard._(coord: c);
  }

  String get _osmPageUrl =>
      'https://www.openstreetmap.org/?mlat=${coord.latitude}&mlon=${coord.longitude}'
      '#map=16/${coord.latitude}/${coord.longitude}';

  @override
  Widget build(BuildContext context) {
    return LatikInfoCard(
      child: InkWell(
        onTap: () => openFileUrl(
          context,
          _osmPageUrl,
          emptyMessage: 'Lokasi tidak tersedia',
          failureMessage: 'Gagal membuka peta',
        ),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LatikSectionTitle('Lokasi Lembaga'),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: IgnorePointer(
                child: SizedBox(
                  height: 200,
                  child: FlutterMap(
                    key: ValueKey('${coord.latitude},${coord.longitude}'),
                    options: MapOptions(
                      initialCenter: coord,
                      initialZoom: 16,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: MapConfig.tileUrlTemplate,
                        userAgentPackageName: MapConfig.userAgentPackageName,
                        maxZoom: 16,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: coord,
                            width: 44,
                            height: 44,
                            alignment: Alignment.bottomCenter,
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.error,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                      const OsmAttribution(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Koordinat lat/lng tervalidasi; null bila salah satu kosong/di luar rentang.
LatLng? _parseLatLng(String rawLat, String rawLng) {
  final lat = double.tryParse(rawLat.trim());
  final lng = double.tryParse(rawLng.trim());
  if (lat == null || lng == null) return null;
  if (lat == 0 && lng == 0) return null;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
  return LatLng(lat, lng);
}