import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/auditor_model.dart';
import '../../../data/services/auditor_ext_payload.dart';
import '../../shared/pks_notice.dart';

/// Langkah 4 — konfirmasi biaya + ajukan. Biaya display-only (spec §4); invoice
/// server tetap otoritatif. Untuk resubmit (status "2") tak ada tagihan baru.
class KonfirmasiStep extends StatelessWidget {
  const KonfirmasiStep({
    super.key,
    required this.auditors,
    required this.submitting,
    required this.editable,
    required this.isResubmit,
    required this.onBack,
    required this.onSubmit,
  });

  final List<AuditorModel> auditors;
  final bool submitting;
  final bool editable;
  final bool isResubmit;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      for (final a in auditors)
        LatikRegAuditorItem(ref: a.id, nama: a.nama, status: a.status),
    ];
    const base = 5000000;
    final total = latikRegistrationTotal(items);
    final firstTetapIdx = items.indexWhere((a) => a.isTetap);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: ListView(
        children: [
          const PksNotice(),
          const SizedBox(height: AppTheme.spacing16),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rincian Biaya',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                _row(theme, 'Registrasi LATIK',
                    AppFormatters.formatRupiah(base)),
                const SizedBox(height: 8),
                // Auditor gratis (Tetap pertama) tampil lebih dulu di bawah
                // Registrasi LATIK, lalu auditor berbayar.
                if (firstTetapIdx != -1) ...[
                  _row(
                    theme,
                    'Auditor: ${items[firstTetapIdx].nama} (Tetap)',
                    'Gratis',
                  ),
                  const SizedBox(height: 8),
                ],
                for (var i = 0; i < items.length; i++) ...[
                  if (i != firstTetapIdx) ...[
                    _row(
                      theme,
                      'Auditor: ${items[i].nama}'
                          '${items[i].isTetap ? " (Tetap)" : ""}',
                      AppFormatters.formatRupiah(1000000),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(
                      AppFormatters.formatRupiah(total),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            isResubmit
                ? 'Pengajuan sebelumnya dikembalikan. Menekan "Ajukan '
                    'Verifikasi" akan mengirim ulang untuk diverifikasi tanpa '
                    'membuat tagihan baru. Rincian di atas hanya ringkasan '
                    'biaya registrasi awal.'
                : 'Dengan menekan "Ajukan Verifikasi", tagihan akan dibuat dan '
                    'pengajuan dikirim untuk verifikasi. Kode tagihan dapat '
                    'dilihat pada halaman Transaksi.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          if (!editable) ...[
            const SizedBox(height: AppTheme.spacing12),
            Text(
              'Data LATIK sedang tidak dapat diajukan (read-only).',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: AppTheme.spacing24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: submitting ? null : onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing12),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium)),
                  ),
                  child: const Text('Kembali'),
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: ElevatedButton(
                  onPressed: (submitting || !editable) ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.textSecondary.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing12),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium)),
                  ),
                  child: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Ajukan Verifikasi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      );
}