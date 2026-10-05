import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/latik_profile.dart';

/// Registration-status card on the dashboard. Tapping routes by verification
/// status (wizard / transaksi / read-only detail).
class LatikSummaryCard extends StatelessWidget {
  const LatikSummaryCard({super.key, required this.data});

  final LatikProfile data;

  @override
  Widget build(BuildContext context) {
    final nomorRegistrasi =
        data.noPendaftaran.isEmpty ? '-' : data.noPendaftaran;
    final fallbackStatus = data.noStr.isEmpty ? 'Data LATIK' : 'STR Aktif';
    final status = data.statusText.isEmpty ? fallbackStatus : data.statusText;
    final isVerified = data.isVerified;
    final statusIcon =
        isVerified ? Icons.check_circle_rounded : Icons.hourglass_top_rounded;
    final statusColor = isVerified ? const Color(0xFF25B45B) : AppColors.accent;
    final statusVerifikasi = data.statusVerifikasi.trim();
    final parsedStatus = int.tryParse(statusVerifikasi);
    final canContinue = data.editable &&
        (statusVerifikasi.isEmpty || parsedStatus == 0 || parsedStatus == 2);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _onCardTap(context, data),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFEAF2FF)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE4ECF7)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B2D5C).withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status Registrasi',
                style: TextStyle(
                  color: Color(0xFF5B6880),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Color(0xFF1C2638),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFA7B0C3)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'No. Registrasi · $nomorRegistrasi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF5B6880),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (canContinue) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        context.push(AppRoutes.verifikasiLatik, extra: data),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_forward_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Lanjutkan Verifikasi Ajuan'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onCardTap(BuildContext context, LatikProfile data) {
    context.push(AppRoutes.profilLembaga);
  }
}
