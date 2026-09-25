import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/api_response_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/url_opener.dart';
import '../../../../data/models/profil_dokumen.dart';
import 'berkas_colors.dart';
import 'status_pill.dart';

/// One document card with icon, name, metadata and status pill.
class DocCard extends StatelessWidget {
  const DocCard({super.key, required this.doc});

  final ProfilDokumen doc;

  @override
  Widget build(BuildContext context) {
    final metaParts = [
      if (doc.nomor.isNotEmpty) 'No: ${doc.nomor}',
      if (doc.tanggal.isNotEmpty) _tanggalText(doc.tanggal),
    ];

    final hasFile = doc.url.trim().isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      child: InkWell(
        onTap: hasFile ? () => _openDoc(context, doc) : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            border: Border.all(color: berkasCardBorder.withValues(alpha: 0.6)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: berkasBlueTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _docIcon(doc.nama),
                      size: 22,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.nama.isEmpty ? 'Dokumen' : doc.nama,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                        if (metaParts.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            metaParts.join('  •  '),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        StatusPill(doc: doc),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (hasFile)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Buka',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.open_in_new,
                            size: 13,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (doc.catatan.trim().isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Divider(height: 1, color: berkasCardDivider),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Keterangan: ${doc.catatan.trim()}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _tanggalText(String raw) {
    final date = parseFlexibleDate(raw);
    return date != null ? AppFormatters.formatShortDate(date) : raw.trim();
  }
}

IconData _docIcon(String nama) {
  final t = nama.toLowerCase();
  if (t.contains('akta') || t.contains('badan hukum')) {
    return Icons.workspace_premium_outlined;
  }
  if (t.contains('nib') || t.contains('berusaha') || t.contains('bkpm')) {
    return Icons.badge_outlined;
  }
  if (t.contains('akreditasi') || t.contains('komite akreditasi')) {
    return Icons.assignment_turned_in_outlined;
  }
  if (t.contains('struktur')) return Icons.account_tree_outlined;
  if (t.contains('sop') || t.contains('pernyataan')) {
    return Icons.verified_user_outlined;
  }
  if (t.contains('npwp')) return Icons.description_outlined;
  return Icons.description_outlined;
}

Future<void> _openDoc(BuildContext context, ProfilDokumen doc) =>
    openFileUrl(context, doc.url);