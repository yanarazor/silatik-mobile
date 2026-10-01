import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/registrasi_model.dart';
import 'widgets/revisi_dokumen_file_box.dart';
import 'widgets/revisi_dokumen_metadata.dart';

/// Reusable revision document card with verification status, verifier notes,
/// replacement file controls, and metadata fields.
class RevisiDokumenCard extends StatelessWidget {
  const RevisiDokumenCard({
    super.key,
    required this.title,
    required this.statusVerifikasi,
    required this.catatanVerifikasi,
    required this.fileRequired,
    required this.nomorRequired,
    required this.tanggalRequired,
    required this.nomor,
    required this.tanggal,
    required this.fileUrl,
    required this.localFile,
    required this.onPick,
    required this.onPreview,
    required this.onNomorChanged,
    required this.onTanggalPicked,
  });

  final String title;
  final int statusVerifikasi;
  final String catatanVerifikasi;
  final bool fileRequired;
  final bool nomorRequired;
  final bool tanggalRequired;
  final String nomor;
  final DateTime? tanggal;
  final String? fileUrl;
  final FileItem? localFile;
  final VoidCallback onPick;
  final VoidCallback onPreview;
  final ValueChanged<String> onNomorChanged;
  final VoidCallback onTanggalPicked;

  bool get _isValid => statusVerifikasi == 1;
  bool get _isInvalid => statusVerifikasi == 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(
          color: _isInvalid
              ? const Color(0xFFFECACA)
              : (_isValid ? const Color(0xFFBBF7D0) : const Color(0xFFE5E7EB)),
          width: _isInvalid || _isValid ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    children: fileRequired
                        ? const [
                            TextSpan(
                              text: ' *',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ]
                        : const [],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(),
            ],
          ),
          if (_isInvalid && catatanVerifikasi.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildVerifierNote(),
          ],
          const SizedBox(height: 14),
          RevisiDokumenFileBox(
            isValid: _isValid,
            fileUrl: fileUrl,
            localFile: localFile,
            onPick: onPick,
            onPreview: onPreview,
          ),
          if (nomorRequired || tanggalRequired) ...[
            const SizedBox(height: 14),
            RevisiDokumenMetadata(
              title: title,
              isValid: _isValid,
              nomorRequired: nomorRequired,
              tanggalRequired: tanggalRequired,
              nomor: nomor,
              tanggal: tanggal,
              onNomorChanged: onNomorChanged,
              onTanggalPicked: onTanggalPicked,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final Color bgColor;
    final Color fgColor;
    final Color borderColor;
    final String label;
    final IconData icon;

    if (_isValid) {
      bgColor = const Color(0xFFF0FDF4);
      fgColor = const Color(0xFF16A34A);
      borderColor = const Color(0xFFBBF7D0);
      label = 'Valid';
      icon = Icons.lock_outline_rounded;
    } else if (_isInvalid) {
      bgColor = const Color(0xFFFEF2F2);
      fgColor = const Color(0xFFDC2626);
      borderColor = const Color(0xFFFECACA);
      label = 'Tidak Valid';
      icon = Icons.error_outline_rounded;
    } else {
      bgColor = const Color(0xFFFFFBEB);
      fgColor = const Color(0xFFD97706);
      borderColor = const Color(0xFFFDE68A);
      label = 'Belum Diverifikasi';
      icon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifierNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCCD5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.feedback_outlined,
            size: 16,
            color: Color(0xFFE11D48),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catatan Verifikator:',
                  style: TextStyle(
                    color: Color(0xFF9F1239),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  catatanVerifikasi,
                  style: const TextStyle(
                    color: Color(0xFF881337),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
