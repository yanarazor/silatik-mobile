import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/profil_dokumen.dart';
import 'berkas_colors.dart';

/// Status pill for a document: verified / pending / not uploaded.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.doc});

  final ProfilDokumen doc;

  @override
  Widget build(BuildContext context) {
    final verified = doc.terverifikasi;
    final uploaded = doc.url.trim().isNotEmpty;
    final color = verified ? berkasGreen : AppColors.textSecondary;
    final label = verified
        ? 'Terverifikasi'
        : uploaded
            ? 'Belum Diverifikasi'
            : 'Belum Diunggah';
    final icon = verified
        ? Icons.check_circle
        : uploaded
            ? Icons.schedule
            : Icons.upload_file_outlined;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}