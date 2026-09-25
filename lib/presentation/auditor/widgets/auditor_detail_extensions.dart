import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/auditor_extension.dart';
import '../../../data/models/auditor_model.dart';
import 'detail_section.dart';

/// Riwayat perpanjangan cards for an auditor.
class AuditorDetailExtensions extends StatelessWidget {
  const AuditorDetailExtensions({super.key, required this.auditor});

  final AuditorModel auditor;

  @override
  Widget build(BuildContext context) {
    final ext = auditor.auditorExt;
    if (ext.isEmpty) {
      return const DetailEmptySection('Belum ada riwayat perpanjangan');
    }
    return Column(
      children: [
        for (var i = 0; i < ext.length; i++) ...[
          _buildExtensionCard(context, ext[i]),
          if (i != ext.length - 1) const SizedBox(height: AppTheme.spacing8),
        ],
      ],
    );
  }

  Widget _buildExtensionCard(BuildContext context, AuditorExtension ext) {
    final (chipLabel, chipColor) = _extStatus(ext);
    final period = _extPeriod(ext);
    final invoice = ext.invoice;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  period,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DetailChip(
                chipLabel,
                bg: chipColor.withValues(alpha: 0.12),
                fg: chipColor,
              ),
            ],
          ),
          if (ext.catatanVerifikasi.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              ext.catatanVerifikasi.trim(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacing8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: invoice == null
                    ? const Text(
                        'Belum ada tagihan',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      )
                    : Row(
                        children: [
                          const Text(
                            'Kode: ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              invoice.kodeTagihan,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              Text(
                invoice == null
                    ? '-'
                    : AppFormatters.formatRupiah(invoice.tagihanTotal),
                style: TextStyle(
                  color: invoice == null
                      ? AppColors.textSecondary
                      : AppColors.primaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (String, Color) _extStatus(AuditorExtension ext) {
    if (ext.status == 3) {
      return (
        ext.invoice?.status == 2 ? 'Selesai / Lunas' : 'Selesai',
        AppColors.success
      );
    }
    if (ext.status == 1) return ('Dalam Proses', AppColors.warning);
    return ('Draft', AppColors.textSecondary);
  }

  String _extPeriod(AuditorExtension ext) {
    final start = AppFormatters.formatShortDate(ext.strTanggalAwal);
    final end = AppFormatters.formatShortDate(ext.strTanggalAkhir);
    if (ext.strTanggalAkhir == null) {
      return '${ext.strTanggalAwal == null ? '—' : start} - Sedang Berjalan';
    }
    return '$start - $end';
  }
}