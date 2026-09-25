import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/auditor_model.dart';
import '../../../providers/auditor_provider.dart';
import '../form/auditor_form_screen.dart';

/// Bottom action buttons: Ajukan Penambahan / Edit / Hapus, each gated by the
/// auditor's `canEdit`/`canDelete` and `auditorStep`.
class AuditorDetailActions extends ConsumerWidget {
  const AuditorDetailActions({super.key, required this.auditor});

  final AuditorModel auditor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tombol Ajukan Penambahan hanya saat auditor_step == 0 (belum diajukan).
    // null (field tak dikirim API) atau step lain (ajuan diproses) = sembunyi.
    final canAjukan = auditor.auditorStep == 0;
    // Manage Auditor mixes the web `add-auditor` & `update` flows; only
    // `add-auditor` is handled here. Edit & Delete are gated by STR /
    // active invoice / auditor_step (see AuditorModel.canEdit & canDelete).
    // TODO(update-flow): when latik needs to submit/resubmit verification, add
    // the update viewMode gate (Edit always shown; Delete needs editable &&
    // profil.status_verifikasi != 2).
    final showEdit = auditor.canEdit;
    final showHapus = auditor.canDelete;
    return Column(
      children: [
        if (canAjukan) ...[
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  context.push(AppRoutes.penambahanAuditor, extra: auditor),
              icon: const Icon(Icons.person_add_alt_1, size: 20),
              label: const Text(
                'Ajukan Penambahan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                ),
              ),
            ),
          ),
        ],
        if (showEdit) ...[
          if (canAjukan) const SizedBox(height: AppTheme.spacing12),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final changed =
                    await openAuditorForm(context, initial: auditor);
                if (changed == true && context.mounted) navigator.pop();
              },
              icon: const Icon(Icons.edit_square, size: 20),
              label: const Text(
                'Edit Auditor',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                ),
              ),
            ),
          ),
        ],
        if (showHapus) ...[
          if (canAjukan || showEdit)
            const SizedBox(height: AppTheme.spacing12),
          SizedBox(
            height: 50,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmHapus(context, ref),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text(
                'Hapus Auditor',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmHapus(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Auditor'),
        content: Text(
          'Apakah Anda yakin ingin menghapus auditor ${auditor.nama}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(auditorRepoProvider).delete(auditor.id);
      ref.invalidate(auditorListProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Auditor dihapus')),
      );
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus auditor: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}