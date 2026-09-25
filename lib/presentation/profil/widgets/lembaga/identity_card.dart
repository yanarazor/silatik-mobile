import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/latik_profile.dart';
import 'lembaga_cards.dart';
import 'lembaga_colors.dart';
import 'str_card.dart';
import 'str_info.dart';

/// Institution identity: name, registration number and status badges, plus the
/// STR card when available.
class IdentityCard extends StatelessWidget {
  const IdentityCard({super.key, required this.data});

  final LatikProfile data;

  @override
  Widget build(BuildContext context) {
    final str = strInfo(data);
    final badges = statusBadges(data);

    final displayName =
        data.namaLatik.isEmpty ? 'Nama Lembaga Belum Diisi' : data.namaLatik;
    final displayReg =
        data.noPendaftaran.isEmpty ? 'Belum Terdaftar' : data.noPendaftaran;

    return LembagaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: lembagaBlueTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: lembagaBlueTintBorder),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.tag,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            displayReg,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final b in badges.isEmpty
                            ? [const PillSpec('Belum Terverifikasi', lembagaAmber)]
                            : badges)
                          Pill(spec: b),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (str != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: Color(0xFFF0F2F7)),
            ),
            StrCard(info: str),
          ],
        ],
      ),
    );
  }
}