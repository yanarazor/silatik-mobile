import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/auditor_model.dart';
import 'cached_remote_image.dart';

class AuditorCheckTile extends StatelessWidget {
  const AuditorCheckTile({
    super.key,
    required this.auditor,
    required this.checked,
    required this.onChanged,
  });

  final AuditorModel auditor;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        onTap: () => onChanged(!checked),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: checked ? AppColors.primary : const Color(0xFFE5E7EB),
              width: checked ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Checkbox(value: checked, onChanged: onChanged),
              _AuditorAvatar(auditor: auditor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auditor.nama.isEmpty ? 'Auditor' : auditor.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIK: ${AppFormatters.maskNik(auditor.nik)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _RoleChip(auditor: auditor),
                        const SizedBox(width: 6),
                        _VerificationBadge(
                            status: auditor.statusVerifikasi ?? 0),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditorAvatar extends StatelessWidget {
  const _AuditorAvatar({required this.auditor});

  final AuditorModel auditor;

  static const _gradients = [
    [Color(0xFF004A8F), Color(0xFF0074D9)],
    [Color(0xFFB5651D), Color(0xFFD4943A)],
    [Color(0xFF4A5568), Color(0xFF718096)],
    [Color(0xFF004A8F), Color(0xFF0D9488)],
  ];

  @override
  Widget build(BuildContext context) {
    final initials = auditor.nama
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();
    final url = auditor.fotoUrl.trim();
    final gradient =
        _gradients[auditor.nama.hashCode.abs() % _gradients.length];

    Widget initialsText() => Text(
          initials.isEmpty ? '?' : initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        );

    final avatar = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: url.isEmpty
          ? initialsText()
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedRemoteImage(
                url: url,
                width: 44,
                height: 44,
                fallback: initialsText(),
              ),
            ),
    );

    if (auditor.statusAktif != 1) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child:
                const Icon(Icons.check_rounded, size: 10, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.auditor});

  final AuditorModel auditor;

  @override
  Widget build(BuildContext context) {
    final isTetap = auditor.statusLabel.toLowerCase().contains('tetap');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isTetap ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isTetap ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        auditor.statusLabel,
        style: TextStyle(
          color: isTetap ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.status});

  final int status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg, dot) = switch (status) {
      1 => (
          'Valid',
          const Color(0xFFECFDF5),
          const Color(0xFF047857),
          const Color(0xFF10B981),
        ),
      2 => (
          'Invalid',
          const Color(0xFFF1F5F9),
          const Color(0xFF475569),
          const Color(0xFF94A3B8),
        ),
      _ => (
          'Belum Verifikasi',
          const Color(0xFFFEF2F2),
          const Color(0xFFB91C1C),
          const Color(0xFFEF4444),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
