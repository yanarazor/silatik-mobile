import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/auditor_model.dart';
import '../../../providers/auditor_provider.dart';

/// Dashboard section summarising the LATIK auditor roster: total, STR
/// near-expiry, STR expired, and unverified counts. Counts are derived on the
/// client from [auditorListProvider] so the tile numbers always agree with the
/// auditor list screen.
class AuditorSummarySection extends ConsumerWidget {
  const AuditorSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditorsAsync = ref.watch(auditorListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(total: auditorsAsync.valueOrNull?.length),
        const SizedBox(height: 14),
        auditorsAsync.when(
          data: (auditors) => _buildGrid(context, auditors),
          loading: () => const _SkeletonGrid(),
          error: (_, __) => _buildErrorGrid(context),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, List<AuditorModel> auditors) {
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

  Widget _buildErrorGrid(BuildContext context) {
    return const _TilesGrid(
      total: '-',
      expiringSoon: '-',
      expired: '-',
      unverified: '-',
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({this.total});

  final int? total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Ringkasan Auditor',
            style: TextStyle(
              color: Color(0xFF0C2D5C),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton(
          onPressed: () => context.push(AppRoutes.auditors),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: AppColors.primary,
          ),
          child: Text(
            total == null ? 'Semua ›' : 'Semua ($total) ›',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
        ),
      ],
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
                value: total,
                label: 'Total Auditor LATIK',
                numberColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                value: expiringSoon,
                label: 'STR akan kadaluarsa (≤7 hari)',
                numberColor: const Color(0xFFB87A00),
                background: const Color(0xFFFFF9EE),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                value: expired,
                label: 'STR telah kadaluarsa',
                numberColor: AppColors.error,
                background: const Color(0xFFFEF3F3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                value: unverified,
                label: 'Auditor belum terverifikasi',
                numberColor: const Color(0xFFB47E00),
                background: const Color(0xFFFFFAEE),
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
    required this.value,
    required this.label,
    required this.numberColor,
    this.background = Colors.white,
  });

  final String value;
  final String label;
  final Color numberColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: background,
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
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: numberColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B778C),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
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
