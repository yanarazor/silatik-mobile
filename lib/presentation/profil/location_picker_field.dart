import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/map_config.dart';
import '../../core/theme/app_theme.dart';

class LocationPickerField extends StatefulWidget {
  const LocationPickerField({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final LatLng? initial;
  final void Function(LatLng position) onChanged;

  @override
  State<LocationPickerField> createState() => _LocationPickerFieldState();
}

class _LocationPickerFieldState extends State<LocationPickerField> {
  static const LatLng _fallback = LatLng(-6.2088, 106.8456); // Jakarta

  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'User-Agent': 'id.go.brin.silatik'},
  ));

  late LatLng _marker;
  Timer? _debounce;
  bool _searching = false;
  List<_Place> _results = const [];

  @override
  void initState() {
    super.initState();
    _marker = widget.initial ?? _fallback;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _dio.close(force: true);
    super.dispose();
  }

  void _setMarker(LatLng pos, {bool move = false}) {
    setState(() => _marker = pos);
    if (move) _mapController.move(pos, _mapController.camera.zoom);
    widget.onChanged(pos);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.length < 3) {
      setState(() => _results = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () => _search(q));
  }

  Future<void> _search(String query) async {
    setState(() => _searching = true);
    try {
      final res = await _dio.get<List<dynamic>>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'format': 'json',
          'q': query,
          'limit': 6,
          'addressdetails': 0,
        },
      );
      final data = res.data ?? const [];
      final places = data
          .whereType<Map<String, dynamic>>()
          .map(_Place.tryFrom)
          .whereType<_Place>()
          .toList();
      if (!mounted) return;
      setState(() => _results = places);
    } catch (_) {
      if (!mounted) return;
      setState(() => _results = const []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _pickResult(_Place place) {
    FocusScope.of(context).unfocus();
    setState(() {
      _results = const [];
      _searchCtrl.text = place.label;
    });
    _setMarker(place.position, move: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchCtrl,
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          onSubmitted: (v) {
            _debounce?.cancel();
            final q = v.trim();
            if (q.length >= 3) _search(q);
          },
          decoration: InputDecoration(
            hintText: 'Cari lokasi (alamat, kota, tempat)',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (_searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _results = const []);
                        },
                      )
                    : null),
          ),
        ),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: const Color(0xFFE5EAF3)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _results.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFF0F2F7)),
              itemBuilder: (_, i) {
                final p = _results[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined,
                      color: AppColors.primary, size: 20),
                  title: Text(
                    p.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () => _pickResult(p),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: SizedBox(
            height: 240,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _marker,
                initialZoom: 15,
                onTap: (_, latLng) => _setMarker(latLng),
              ),
              children: [
                TileLayer(
                  urlTemplate: MapConfig.tileUrlTemplate,
                  userAgentPackageName: MapConfig.userAgentPackageName,
                  maxZoom: 18,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _marker,
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ketuk peta atau cari lokasi untuk menaruh penanda. '
          'Lat: ${_marker.latitude.toStringAsFixed(6)}, '
          'Lng: ${_marker.longitude.toStringAsFixed(6)}',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _Place {
  const _Place({required this.label, required this.position});

  final String label;
  final LatLng position;

  static _Place? tryFrom(Map<String, dynamic> json) {
    final lat = double.tryParse('${json['lat']}');
    final lon = double.tryParse('${json['lon']}');
    final label = (json['display_name'] ?? '').toString();
    if (lat == null || lon == null || label.isEmpty) return null;
    return _Place(label: label, position: LatLng(lat, lon));
  }
}
