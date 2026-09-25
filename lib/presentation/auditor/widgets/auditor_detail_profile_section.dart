import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/auditor_model.dart';
import '../../../data/models/master_data_model.dart';
import '../../../providers/master_data_provider.dart';
import 'detail_section.dart';

/// Key/value profile rows, resolving province/city codes to their names.
class AuditorDetailProfileSection extends ConsumerWidget {
  const AuditorDetailProfileSection({super.key, required this.auditor});

  final AuditorModel auditor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (provinsi, kabupaten) = _resolveRegion(ref);
    final rows = <(String, String, bool)>[
      ('Email', auditor.email, false),
      ('No. Handphone', auditor.phone, false),
      (
        'Tempat, Tanggal Lahir',
        [auditor.tempatLahir, AppFormatters.formatDate(auditor.tanggalLahir)]
            .where((e) => e.isNotEmpty && e != '-')
            .join(', '),
        false
      ),
      ('Alamat Domisili', auditor.alamat, false),
      (
        'Kab/Kota & Provinsi',
        [kabupaten, provinsi].where((e) => e.isNotEmpty).join(', '),
        false
      ),
      ('Kode Pos', auditor.kodePos, false),
      ('Agama', auditor.agama, false),
      ('Status Auditor', auditor.statusLabel, true),
      // ('Status Keaktifan', _auditor.activeLabel, false),
      ('Keterangan', auditor.keterangan, false),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          _profileRow(rows[i].$1, rows[i].$2, emphasized: rows[i].$3),
          if (i != rows.length - 1) const DetailSectionDivider(),
        ],
      ],
    );
  }

  Widget _profileRow(String label, String value, {bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value.isEmpty ? '-' : value,
            style: TextStyle(
              color:
                  emphasized ? AppColors.primaryLight : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Provinsi/kabupaten disimpan sebagai kode di API auditor; resolusi ke nama
  /// dari master /provinsi & /kabupaten. Nilai non-numerik dianggap sudah nama.
  (String, String) _resolveRegion(WidgetRef ref) {
    final rawProv = auditor.provinsi.trim();
    final rawKab = auditor.kabupaten.trim();
    final provinsiAll =
        ref.watch(provinsiListProvider).valueOrNull ?? const <ProvinsiModel>[];
    var kabProvId = _isNumericId(rawProv) ? rawProv : null;
    var provinsi = rawProv;
    if (kabProvId != null) {
      for (final p in provinsiAll) {
        if (p.id == rawProv) {
          provinsi = p.nama;
          break;
        }
      }
    } else if (provinsiAll.isNotEmpty) {
      for (final p in provinsiAll) {
        if (p.nama == rawProv) {
          provinsi = p.nama;
          kabProvId = p.id;
          break;
        }
      }
    }
    var kabupaten = rawKab;
    if (kabProvId != null && _isNumericId(rawKab)) {
      final kabs = ref.watch(kabupatenListProvider(kabProvId)).valueOrNull ??
          const <KabupatenModel>[];
      for (final k in kabs) {
        if (k.id == rawKab) {
          kabupaten = k.nama;
          break;
        }
      }
    }
    return (provinsi, kabupaten);
  }

  bool _isNumericId(String value) =>
      value.isNotEmpty && RegExp(r'^\d+$').hasMatch(value);
}