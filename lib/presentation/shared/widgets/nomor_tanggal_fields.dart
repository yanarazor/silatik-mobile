import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// Input Nomor + Tanggal opsional untuk satu dokumen, dipasang sebagai
/// `DokumenUploadCard.extraFields` pada alur perpanjangan (LATIK & Auditor).
/// Mengambil primitif (bukan model provider) agar bisa dipakai lintas alur.
class NomorTanggalFields extends StatelessWidget {
  const NomorTanggalFields({
    super.key,
    required this.showNomor,
    required this.showTanggal,
    required this.nomor,
    required this.tanggal,
    required this.onNomor,
    required this.onTanggal,
  });

  final bool showNomor;
  final bool showTanggal;
  final String nomor;
  final DateTime? tanggal;
  final ValueChanged<String> onNomor;
  final VoidCallback onTanggal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showNomor) ...[
          _label(theme, 'Nomor'),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: nomor,
            onChanged: onNomor,
            decoration: _inputDecoration('Masukkan nomor dokumen'),
          ),
          const SizedBox(height: AppTheme.spacing8),
        ],
        if (showTanggal) ...[
          _label(theme, 'Tanggal'),
          const SizedBox(height: 4),
          InkWell(
            onTap: onTanggal,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: InputDecorator(
              decoration: _inputDecoration('Pilih tanggal').copyWith(
                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
              ),
              child: Text(
                tanggal != null
                    ? AppFormatters.formatDate(tanggal)
                    : 'Pilih tanggal',
                style: TextStyle(
                  color: tanggal != null
                      ? const Color(0xFF111827)
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _label(ThemeData theme, String text) => RichText(
        text: TextSpan(
          text: text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          children: const [
            TextSpan(text: ' *', style: TextStyle(color: AppColors.error)),
          ],
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      );
}