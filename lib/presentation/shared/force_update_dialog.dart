import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class ForceUpdateDialog extends StatelessWidget {
  const ForceUpdateDialog({
    super.key,
    required this.latestVersion,
    required this.force,
    required this.onUpdatePressed,
  });

  final String latestVersion;
  final bool force;
  final VoidCallback onUpdatePressed;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !force,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        icon: const Icon(Icons.system_update_alt,
            color: AppColors.primary, size: 40),
        title: const Text(
          'Update Tersedia',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          force
              ? 'Versi terbaru sudah tersedia. Silakan perbarui aplikasi untuk '
                  'melanjutkan.'
              : 'Versi terbaru sudah tersedia. Perbarui aplikasi untuk '
                  'mendapatkan perbaikan dan fitur terbaru.',
          textAlign: TextAlign.center,
        ),
        actions: [
          if (force)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onUpdatePressed,
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Perbarui Sekarang'),
              ),
            )
          else ...[
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Nanti Saja'),
            ),
            FilledButton(
              onPressed: onUpdatePressed,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Perbarui Sekarang'),
            ),
          ],
        ],
      ),
    );
  }
}
