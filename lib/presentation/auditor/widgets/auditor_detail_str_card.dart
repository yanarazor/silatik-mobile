import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/auditor_model.dart';
import 'detail_section.dart';

/// STR (Surat Tanda Registrasi) summary card shown inside the header.
class AuditorDetailStrCard extends StatelessWidget {
  const AuditorDetailStrCard({super.key, required this.auditor});

  final AuditorModel auditor;

  bool get _strExpired =>
      auditor.strTanggalAkhir != null &&
      auditor.strTanggalAkhir!.isBefore(DateTime.now());

  bool get _strValid => auditor.strStatus == 1 && !_strExpired;

  @override
  Widget build(BuildContext context) {
    final String strLabel;
    final Color strColor;
    if (_strValid) {
      strLabel = 'Berlaku / Sah';
      strColor = AppColors.success;
    } else if (_strExpired) {
      strLabel = 'Kedaluwarsa';
      strColor = AppColors.error;
    } else {
      strLabel = 'Belum Disahkan';
      strColor = AppColors.warning;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user,
                  size: 18, color: AppColors.primaryLight),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Surat Tanda Registrasi (STR)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DetailChip(
                strLabel,
                bg: strColor.withValues(alpha: 0.12),
                fg: strColor,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              Expanded(
                child: _strField(
                    'Nomor STR', auditor.strNo, AppColors.textPrimary),
              ),
              Expanded(
                child: _strField(
                  'Masa Berlaku',
                  _period(auditor.strTanggalAwal, auditor.strTanggalAkhir),
                  _strExpired ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _strField(String label, String value, Color valueColor) {
    return Column(
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
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '-' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _period(DateTime? start, DateTime? end) {
    final parts = [
      if (start != null) AppFormatters.formatShortDate(start),
      if (end != null) AppFormatters.formatShortDate(end),
    ];
    return parts.isEmpty ? '-' : parts.join(' - ');
  }
}