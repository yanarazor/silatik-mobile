import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/latik_experience.dart';
import 'lembaga_colors.dart';

class ExperienceCountBadge extends StatelessWidget {
  const ExperienceCountBadge(this.count, {super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count Riwayat',
        style: const TextStyle(
          color: AppColors.primaryLight,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class EmptyExperience extends StatelessWidget {
  const EmptyExperience({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacing12),
      child: Text(
        'Belum ada pengalaman LATIK',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

class ExperienceCard extends StatelessWidget {
  const ExperienceCard({
    super.key,
    required this.experience,
    required this.editable,
    required this.deleting,
    required this.actionsEnabled,
    required this.onEdit,
    required this.onDelete,
  });

  final LatikExperience experience;
  final bool editable;
  final bool deleting;
  final bool actionsEnabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final canMutate = editable && experience.canEdit;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: lembagaCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: lembagaBlueTint,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              experience.tahun.isEmpty ? '-' : experience.tahun,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  experience.ippdPengguna.isEmpty
                      ? 'IPPD Pengguna'
                      : experience.ippdPengguna,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  experience.objectAudit.isEmpty
                      ? 'Obyek audit tidak tersedia'
                      : experience.objectAudit,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (canMutate) ...[
            const SizedBox(width: AppTheme.spacing4),
            if (deleting)
              const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              PopupMenuButton<ExperienceAction>(
                enabled: actionsEnabled,
                tooltip: 'Aksi pengalaman',
                onSelected: (action) {
                  if (action == ExperienceAction.edit) {
                    onEdit();
                  } else {
                    onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: ExperienceAction.edit,
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: ExperienceAction.delete,
                    child: Text(
                      'Hapus',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

enum ExperienceAction { edit, delete }
