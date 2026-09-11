import 'package:flutter/material.dart';

/// Title + optional subtitle rendered on the blue header band.
///
/// Shared so every band-header screen (auditor list, notifikasi, …) uses the
/// same type scale and color instead of re-declaring the styles per screen.
/// An optional [trailing] holds a right-aligned action such as an add or close
/// button.
class HeaderTitle extends StatelessWidget {
  const HeaderTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Color(0xDDEAF2FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
