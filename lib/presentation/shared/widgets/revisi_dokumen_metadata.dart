import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// Editable or locked metadata fields (Nomor & Tanggal) for [RevisiDokumenCard].
class RevisiDokumenMetadata extends StatelessWidget {
  const RevisiDokumenMetadata({
    super.key,
    required this.title,
    required this.isValid,
    required this.nomorRequired,
    required this.tanggalRequired,
    required this.nomor,
    required this.tanggal,
    required this.onNomorChanged,
    required this.onTanggalPicked,
  });

  final String title;
  final bool isValid;
  final bool nomorRequired;
  final bool tanggalRequired;
  final String nomor;
  final DateTime? tanggal;
  final ValueChanged<String> onNomorChanged;
  final VoidCallback onTanggalPicked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (nomorRequired) ...[
          _buildFieldLabel(theme, 'Nomor Dokumen'),
          const SizedBox(height: 4),
          TextFormField(
            key: ValueKey('nomor_$title'),
            initialValue: nomor,
            enabled: !isValid,
            onChanged: onNomorChanged,
            style: TextStyle(
              color:
                  isValid ? const Color(0xFF64748B) : const Color(0xFF111827),
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: 'Masukkan nomor dokumen',
              isDense: true,
              filled: isValid,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (tanggalRequired) ...[
          _buildFieldLabel(theme, 'Tanggal Dokumen'),
          const SizedBox(height: 4),
          InkWell(
            onTap: isValid ? null : onTanggalPicked,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: InputDecorator(
              decoration: InputDecoration(
                hintText: 'Pilih tanggal',
                isDense: true,
                filled: isValid,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
              child: Text(
                tanggal != null
                    ? AppFormatters.formatDate(tanggal)
                    : 'Pilih tanggal',
                style: TextStyle(
                  color: tanggal != null
                      ? (isValid
                          ? const Color(0xFF64748B)
                          : const Color(0xFF111827))
                      : AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFieldLabel(ThemeData theme, String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        children: const [
          TextSpan(text: ' *', style: TextStyle(color: AppColors.error)),
        ],
      ),
    );
  }
}
