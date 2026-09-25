import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/latik_profile.dart';
import 'widgets/latik_info_parts.dart';

class LatikInfoSection extends StatelessWidget {
  const LatikInfoSection({super.key, required this.data});

  final LatikProfile data;

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();

    return LatikInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LatikSectionTitle('Informasi Lembaga'),
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
      rows.add(LatikValueRow(
          label: 'Nomor Registrasi', value: noRegistrasi, mono: true));
    }
    if (nib.isNotEmpty) {
      rows.add(LatikValueRow(
        label: 'Nomor Induk Berusaha (NIB)',
        value: nib,
        mono: true,
        trailing: const Icon(Icons.verified_rounded,
            size: 16, color: Color(0xFF25B45B)),
      ));
    }
    if (npwp.isNotEmpty) {
      rows.add(LatikValueRow(label: 'NPWP Institusi', value: npwp, mono: true));
    }
    if (nama.isNotEmpty) {
      rows.add(LatikValueRow(label: 'Nama Lembaga', value: nama));
    }
    if (email.isNotEmpty) {
      rows.add(LatikValueRow(
        label: 'Email Institusi',
        value: email,
        valueColor: AppColors.primaryLight,
        onTap: () => _launchUrl(email, mailto: true),
      ));
    }
    if (alamat.isNotEmpty) {
      rows.add(LatikValueRow(label: 'Alamat Lengkap', value: alamat));
    }
    if (telepon.isNotEmpty) {
      rows.add(LatikValueRow(label: 'Nomor Telepon Kantor', value: telepon));
    }
    if (website.isNotEmpty) {
      rows.add(LatikValueRow(
        label: 'Website Resmi',
        value: website,
        valueColor: AppColors.primaryLight,
        trailing: const Icon(Icons.open_in_new,
            size: 16, color: AppColors.primaryLight),
        onTap: () => _launchUrl(website),
      ));
    }
    if (areaOperasional.isNotEmpty) {
      rows.add(LatikValueRow(label: 'Area Operasional', value: areaOperasional));
    }
    if (scopes.isNotEmpty) {
      rows.add(LatikValueRow(
        label: 'Lingkup Pendaftaran',
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final s in scopes) LatikScopeChip(label: s)],
        ),
      ));
    }
    return rows;
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