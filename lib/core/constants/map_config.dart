import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapConfig {
  const MapConfig._();

  static String get tileUrlTemplate =>
      dotenv.env['MAP_TILE_URL'] ??
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const String userAgentPackageName = 'id.go.brin.silatik';
}
