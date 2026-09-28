import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/latik_profile.dart';
import '../../../providers/latik_verifikasi_provider.dart';
import 'summary_line.dart';

/// Registration-status card on the dashboard. Tapping routes by verification
/// status (wizard / transaksi / read-only detail).
class LatikSummaryCard extends StatelessWidget {
  const LatikSummaryCard({super.key, required this.data});

  final LatikProfile data;

  @override
  Widget build(BuildContext context) {
    final nomorStr = data.noStr.isEmpty ? '-' : data.noStr;
    final nomorRegistrasi =
        data.noPendaftaran.isEmpty ? '-' : data.noPendaftaran;
    final namaLatik = data.namaLatik.isEmpty ? '-' : data.namaLatik;
    final fallbackStatus = data.noStr.isEmpty ? 'Data LATIK' : 'STR Aktif';
    final status = data.statusText.isEmpty ? fallbackStatus : data.statusText;
    final isVerified = data.isVerified;
    final statusIcon =
        isVerified ? Icons.check_circle_rounded : Icons.hourglass_top_rounded;
    final statusColor = isVerified ? const Color(0xFF25B45B) : AppColors.accent;

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
              const SizedBox(height: 18),
              SummaryLine(label: 'No. Registrasi', value: nomorRegistrasi),
              const SizedBox(height: 6),
              SummaryLine(label: 'No. STR', value: nomorStr),
              const SizedBox(height: 6),
              SummaryLine(label: 'Nama LATIK', value: namaLatik),
            ],
          ),
        ),
      ),
    );
  }

  void _onCardTap(BuildContext context, LatikProfile data) {
    if (data.editable) {
      context.push(AppRoutes.verifikasiLatik, extra: data);
      return;
    }

    switch (verifikasiActionFor(data.statusVerifikasi)) {
      case VerifikasiAction.transaksi:
        context.push(AppRoutes.transaksi);
      case VerifikasiAction.wizard:
      case VerifikasiAction.detail:
        context.push(AppRoutes.profilLembaga);
    }
  }
}