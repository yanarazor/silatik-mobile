import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/url_opener.dart';
import 'lembaga_cards.dart';
import 'str_info.dart';

/// STR summary block shown inside the identity card.
class StrCard extends StatelessWidget {
  const StrCard({super.key, required this.info});

  final StrInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAF2FB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Surat Tanda Registrasi (STR)',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Pill(spec: info.statusSpec),
            ],
          ),
          const SizedBox(height: 4),
          PairRow(
            label: 'No. STR',
            value: info.no,
            mono: true,
          ),
          if (info.period.isNotEmpty)
            PairRow(
              label: 'Masa Berlaku',
              value: info.period,
            ),
          if (info.fileUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFEAF2FB)),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => openFileUrl(context, info.fileUrl),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Buka',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.open_in_new_rounded,
                      size: 15, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}