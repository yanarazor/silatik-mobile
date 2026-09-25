import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';

const _cardBorder = Color(0xFFE5EAF3);
const _blueTintBorder = Color(0xFFD5E5F7);
const _scopeBg = Color(0xFFEBF3FC);

/// White rounded card base used by the LATIK info/location sections.
class LatikInfoCard extends StatelessWidget {
  const LatikInfoCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C2D5C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// "Batang biru + teks" section heading.
class LatikSectionTitle extends StatelessWidget {
  const LatikSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 4,
          height: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Label/value row used inside the info card.
class LatikValueRow extends StatelessWidget {
  const LatikValueRow({
    super.key,
    required this.label,
    this.value,
    this.child,
    this.valueColor,
    this.mono = false,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String? value;
  final Widget? child;
  final Color? valueColor;
  final bool mono;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = child ??
        Text(
          value ?? '',
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: mono ? 'monospace' : null,
            height: 1.35,
          ),
        );

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: content),
        if (trailing != null) ...[const SizedBox(width: 6), trailing!],
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          onTap != null
              ? InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: row,
                  ),
                )
              : row,
        ],
      ),
    );
  }
}

/// Chip for one registration scope.
class LatikScopeChip extends StatelessWidget {
  const LatikScopeChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _scopeBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _blueTintBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_scopeIcon(label), size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _scopeIcon(String label) {
    final t = label.toLowerCase();
    if (t.contains('aplikasi')) return Icons.apps_rounded;
    if (t.contains('infrastruktur')) return Icons.lan_rounded;
    if (t.contains('keamanan')) return Icons.security_rounded;
    return Icons.apartment_rounded;
  }
}

/// Small "© OpenStreetMap" attribution overlay for the map tile layer.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomRight,
      child: ColoredBox(
        color: Colors.white70,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            '© OpenStreetMap',
            style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}