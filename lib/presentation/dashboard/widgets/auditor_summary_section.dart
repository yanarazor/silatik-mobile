import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/auditor_model.dart';
import '../../../providers/auditor_provider.dart';

/// Dashboard section summarising the LATIK auditor roster: Total Personil,
/// STR expiring within 7 days, expired STR, and unverified auditors.
class AuditorSummarySection extends ConsumerWidget {
  const AuditorSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditorsAsync = ref.watch(auditorListProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4ECF7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2D5C).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Auditor',
            style: TextStyle(
              color: Color(0xFF0C2D5C),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          auditorsAsync.when(
            data: (auditors) => _buildGrid(auditors),
            loading: () => const _SkeletonGrid(),
            error: (_, __) => const _TilesGrid(
              total: '-',
              expiringSoon: '-',
              expired: '-',
              unverified: '-',
            ),
          ),
          const SizedBox(height: 14),
          _ManageAuditorButton(
            onTap: () => context.go(AppRoutes.auditors),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<AuditorModel> auditors) {
    final now = DateTime.now();
    final total = auditors.length;
    final expiringSoon = auditors.where((a) {
      final end = a.strTanggalAkhir;
      return end != null &&
          !end.isBefore(now) &&
          end.difference(now).inDays <= 7;
    }).length;
    final expired = auditors
        .where((a) =>
            a.strTanggalAkhir != null && a.strTanggalAkhir!.isBefore(now))
        .length;
    final unverified =
        auditors.where((a) => (a.statusVerifikasi ?? 0) != 1).length;

    return _TilesGrid(
      total: '$total',
      expiringSoon: '$expiringSoon',
      expired: '$expired',
      unverified: '$unverified',
    );
  }
}

class _TilesGrid extends StatelessWidget {
  const _TilesGrid({
    required this.total,
    required this.expiringSoon,
    required this.expired,
    required this.unverified,
  });

  final String total;
  final String expiringSoon;
  final String expired;
  final String unverified;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Total Auditor LATIK',
                value: total,
                unit: 'Auditor',
                numberColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'STR akan kadaluarsa (≤7 hari)',
                value: expiringSoon,
                unit: 'Auditor',
                numberColor: const Color(0xFFB87A00),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'STR telah kadaluarsa',
                value: expired,
                unit: 'Auditor',
                numberColor: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Auditor belum terverifikasi',
                value: unverified,
                unit: 'Auditor',
                numberColor: const Color(0xFFB47E00),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.numberColor,
  });

  final String label;
  final String value;
  final String unit;
  final Color numberColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4ECF7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 4, color: numberColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          color: numberColor,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          unit,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B778C),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF5B6880),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageAuditorButton extends StatelessWidget {
  const _ManageAuditorButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF2FF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
        height: 46,
          width: double.infinity,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
                Text(
                  'Kelola Auditor',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: _SkeletonTile()),
            SizedBox(width: 12),
            Expanded(child: _SkeletonTile()),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _SkeletonTile()),
            SizedBox(width: 12),
            Expanded(child: _SkeletonTile()),
          ],
        ),
      ],
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: const Color(0xFFEDF1F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4ECF7)),
      ),
    );
  }
}
