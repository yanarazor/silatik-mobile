import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/auditor_model.dart';
import '../../shared/cached_remote_image.dart';
import 'auditor_detail_str_card.dart';
import 'detail_section.dart';

/// Identity card at the top of the auditor detail screen: avatar, name, NIK
/// (toggleable) and status chips, plus the STR card when present.
class AuditorDetailHeader extends StatefulWidget {
  const AuditorDetailHeader({super.key, required this.auditor});

  final AuditorModel auditor;

  @override
  State<AuditorDetailHeader> createState() => _AuditorDetailHeaderState();
}

class _AuditorDetailHeaderState extends State<AuditorDetailHeader> {
  bool _showNik = false;

  AuditorModel get _auditor => widget.auditor;

  bool get _hasStr =>
      _auditor.strNo.isNotEmpty ||
      _auditor.strTanggalAwal != null ||
      _auditor.strTanggalAkhir != null;

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(context),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _auditor.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _buildNikRow(),
                    const SizedBox(height: 6),
                    _buildHeaderChips(),
                  ],
                ),
              ),
            ],
          ),
          if (_hasStr) ...[
            const SizedBox(height: AppTheme.spacing16),
            const DetailSectionDivider(),
            const SizedBox(height: AppTheme.spacing16),
            AuditorDetailStrCard(auditor: _auditor),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final url = _auditor.fotoUrl.trim();
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedRemoteImage(
        url: url,
        fallback: _buildInitialsAvatar(),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    final initials = _auditor.nama
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();
    return Center(
      child: Text(
        initials.isEmpty ? 'A' : initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildNikRow() {
    final nik = _auditor.nik;
    final nikText = _showNik ? nik : AppFormatters.maskNik(nik);
    return Row(
      children: [
        Flexible(
          child: Text(
            nik.isEmpty ? 'NIK belum diisi' : 'NIK: $nikText',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (nik.isNotEmpty) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => setState(() => _showNik = !_showNik),
            tooltip: _showNik ? 'Sembunyikan NIK' : 'Tampilkan NIK',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            icon: Icon(
              _showNik ? Icons.visibility_off : Icons.visibility,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeaderChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (_auditor.statusAktif == 1)
          DetailChip(
            'Aktif',
            bg: AppColors.success.withValues(alpha: 0.10),
            fg: AppColors.success,
            dot: true,
          )
        else
          DetailChip(
            'Tidak Aktif',
            bg: AppColors.textSecondary.withValues(alpha: 0.10),
            fg: AppColors.textSecondary,
          ),
        if (_auditor.statusVerifikasi == 1)
          DetailChip(
            'Terverifikasi',
            bg: AppColors.primaryLight.withValues(alpha: 0.12),
            fg: AppColors.primaryLight,
            icon: Icons.verified,
          )
        else
          DetailChip(
            'Belum Verifikasi',
            bg: AppColors.textSecondary.withValues(alpha: 0.10),
            fg: AppColors.textSecondary,
            icon: Icons.gpp_bad,
          ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}