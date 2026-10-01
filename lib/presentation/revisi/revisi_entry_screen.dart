import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';

/// Revision request hub for the three supported revision flows.
class RevisiEntryScreen extends StatelessWidget {
  const RevisiEntryScreen({super.key});

  static const _flows = [
    _RevisiFlow(
      title: 'Perpanjangan Registrasi LATIK',
      description: 'Perbaiki dokumen pengajuan perpanjangan lembaga.',
      icon: Icons.business_rounded,
      route: AppRoutes.revisiLatik,
      accent: Color(0xFF1D4ED8),
      tint: Color(0xFFEFF6FF),
    ),
    _RevisiFlow(
      title: 'Perpanjangan Registrasi Auditor',
      description: 'Perbarui dokumen auditor yang dikembalikan.',
      icon: Icons.badge_rounded,
      route: AppRoutes.revisiAuditor,
      accent: Color(0xFF7C3AED),
      tint: Color(0xFFF5F3FF),
    ),
    _RevisiFlow(
      title: 'Penambahan Auditor',
      description: 'Lengkapi kembali pengajuan auditor baru.',
      icon: Icons.person_add_alt_1_rounded,
      route: AppRoutes.revisiAddAuditor,
      accent: Color(0xFF0F766E),
      tint: Color(0xFFF0FDFA),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Revisi Ajuan',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pilih pengajuan yang ingin diperbaiki. Perhatikan catatan verifikator pada setiap dokumen.',
                      style: TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'PENGAJUAN DIKEMBALIKAN',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            for (final flow in _flows) ...[
              _RevisiFlowCard(
                flow: flow,
                onTap: () => context.push(flow.route),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _RevisiFlow {
  const _RevisiFlow({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
    required this.accent,
    required this.tint,
  });

  final String title;
  final String description;
  final IconData icon;
  final String route;
  final Color accent;
  final Color tint;
}

class _RevisiFlowCard extends StatelessWidget {
  const _RevisiFlowCard({required this.flow, required this.onTap});

  final _RevisiFlow flow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: flow.tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(flow.icon, color: flow.accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flow.title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      flow.description,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: flow.accent, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
