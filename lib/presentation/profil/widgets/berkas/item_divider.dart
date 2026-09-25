import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Pemisah antar dokumen. Ruang lebih lega + garis tipis agar tiap blok
/// (kartu + input nomor/tanggal) terbaca sebagai satu kesatuan.
class ItemDivider extends StatelessWidget {
  const ItemDivider({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing20),
        child: Divider(height: 1, thickness: 1, color: Color(0xFFE5EAF3)),
      );
}