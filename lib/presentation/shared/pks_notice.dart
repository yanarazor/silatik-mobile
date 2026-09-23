import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

class PksNotice extends StatelessWidget {
  const PksNotice({super.key});

  static const _address = [
    'Direktorat Alih dan Sistem Audit Teknologi',
    'Kedeputian Pemanfaatan Riset dan Inovasi',
    'Badan Riset dan Inovasi Nasional',
    'Gedung BJ Habibie Lantai 9',
    'Jl. M.H. Thamrin No.8, RT.2/RW.1, Kebon Sirih, Kec. Menteng, '
        'Kota Jakarta Pusat',
    'Daerah Khusus Ibukota Jakarta 10340',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 20, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mohon mengirimkan dokumen PKS bermaterai rangkap 2 ke '
                  'alamat berikut:',
                  style: TextStyle(
                    color: AppColors.warning.withValues(alpha: 0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          for (final line in _address)
            Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 4),
              child: Text(
                line,
                style: TextStyle(
                  color: AppColors.warning.withValues(alpha: 0.95),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
