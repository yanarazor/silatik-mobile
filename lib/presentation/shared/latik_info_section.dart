import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/map_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/url_opener.dart';
import '../../data/models/latik_profile.dart';

const _cardBorder = Color(0xFFE5EAF3);
const _blueTintBorder = Color(0xFFD5E5F7);
const _scopeBg = Color(0xFFEBF3FC);

class LatikInfoSection extends StatelessWidget {
  const LatikInfoSection({super.key, required this.data});

  final LatikProfile data;

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Informasi Lembaga'),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Belum ada data informasi lembaga.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: Color(0xFFF0F2F7)),
              rows[i],
            ],
        ],
      ),
    );
  }

  List<Widget> _buildRows() {
    final noRegistrasi = data.noPendaftaran;
    final nib = data.noNib;
    final npwp = data.noNpwp;
    final nama = data.namaLatik;
    final email = data.email;
    final alamat = data.fullAddress;
    final telepon = data.phone;
    final website = data.website;
    final areaOperasional = data.areaOperasional;
    final scopes = latikScopeLabels(data.scopeSource);

    final rows = <Widget>[];
    if (noRegistrasi.isNotEmpty) {
      rows.add(_ValueRow(label: 'Nomor Registrasi', value: noRegistrasi, mono: true));
    }
    if (nib.isNotEmpty) {
      rows.add(_ValueRow(
        label: 'Nomor Induk Berusaha (NIB)',
        value: nib,
        mono: true,
        trailing: const Icon(Icons.verified_rounded,
            size: 16, color: Color(0xFF25B45B)),
      ));
    }
    if (npwp.isNotEmpty) {
      rows.add(_ValueRow(label: 'NPWP Institusi', value: npwp, mono: true));
    }
    if (nama.isNotEmpty) {
      rows.add(_ValueRow(label: 'Nama Lembaga', value: nama));
    }
    if (email.isNotEmpty) {
      rows.add(_ValueRow(
        label: 'Email Institusi',
        value: email,
        valueColor: AppColors.primaryLight,
        onTap: () => _launchUrl(email, mailto: true),
      ));
    }
    if (alamat.isNotEmpty) {
      rows.add(_ValueRow(label: 'Alamat Lengkap', value: alamat));
    }
    if (telepon.isNotEmpty) {
      rows.add(_ValueRow(label: 'Nomor Telepon Kantor', value: telepon));
    }
    if (website.isNotEmpty) {
      rows.add(_ValueRow(
        label: 'Website Resmi',
        value: website,
        valueColor: AppColors.primaryLight,
        trailing: const Icon(Icons.open_in_new,
            size: 16, color: AppColors.primaryLight),
        onTap: () => _launchUrl(website),
      ));
    }
    if (areaOperasional.isNotEmpty) {
      rows.add(_ValueRow(label: 'Area Operasional', value: areaOperasional));
    }
    if (scopes.isNotEmpty) {
      rows.add(_ValueRow(
        label: 'Lingkup Pendaftaran',
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final s in scopes) _ScopeChip(label: s)],
        ),
      ));
    }
    return rows;
  }
}

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
    return _Card(
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
            const _SectionTitle('Lokasi Lembaga'),
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
                      const _OsmAttribution(),
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

// ---------------------------------------------------------------- helpers

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 4,
          height: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C2D5C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    this.value,
    this.child,
    this.valueColor,
    this.mono = false,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String? value;
  final Widget? child;
  final Color? valueColor;
  final bool mono;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = child ??
        Text(
          value ?? '',
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: mono ? 'monospace' : null,
            height: 1.35,
          ),
        );

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: content),
        if (trailing != null) ...[const SizedBox(width: 6), trailing!],
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          onTap != null
              ? InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: row,
                  ),
                )
              : row,
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _scopeBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _blueTintBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_scopeIcon(label), size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _scopeIcon(String label) {
    final t = label.toLowerCase();
    if (t.contains('aplikasi')) return Icons.apps_rounded;
    if (t.contains('infrastruktur')) return Icons.lan_rounded;
    if (t.contains('keamanan')) return Icons.security_rounded;
    return Icons.apartment_rounded;
  }
}

class _OsmAttribution extends StatelessWidget {
  const _OsmAttribution();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomRight,
      child: ColoredBox(
        color: Colors.white70,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            '© OpenStreetMap',
            style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

Future<void> _launchUrl(String value, {bool mailto = false}) async {
  final uri = mailto
      ? Uri(scheme: 'mailto', path: value)
      : Uri.parse(value.startsWith('http') ? value : 'https://$value');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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

// -------------------------------------------------------------- scope labels

String? latikScopeName(String raw) {
  final t = raw.trim().toLowerCase().replaceAll('_', ' ');
  if (t.isEmpty || t == 'null') return null;
  if (t.contains('aplikasi')) return 'Aplikasi';
  if (t.contains('infrastruktur')) return 'Infrastruktur';
  if (t.contains('keamanan')) return 'Keamanan Informasi';
  if (t.contains('organisasi') || t.contains('tata kelola')) {
    return 'Organisasi';
  }
  return null;
}

List<String> latikScopeLabels(Object? raw) {
  final result = <String>[];

  void add(String? label) {
    if (label != null && !result.contains(label)) result.add(label);
  }

  if (raw is Map) {
    raw.forEach((key, value) {
      if (value == true || value == 1 || value == '1') {
        add(latikScopeName(key.toString()));
      } else if (value is String &&
          const {'true', '1', 'aktif', 'active', 'ya', 'yes'}
              .contains(value.trim().toLowerCase())) {
        add(latikScopeName(key.toString()));
      }
    });
    return result;
  }
  if (raw is List) {
    for (final item in raw) {
      if (item == null) continue;
      add(latikScopeName(item.toString()));
    }
    return result;
  }
  if (raw is String && raw.trim().isNotEmpty && raw != 'null') {
    for (final part in raw.split(',')) {
      add(latikScopeName(part));
    }
  }
  return result;
}
