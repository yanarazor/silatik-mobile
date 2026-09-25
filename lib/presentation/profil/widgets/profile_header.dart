import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Gradient header on the profile tab: avatar/initials, name, institution and
/// account-status badge.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.topInset,
    required this.name,
    required this.isActive,
    this.avatarUrl,
    this.lembagaName,
    this.registrationNumber,
  });

  final double topInset;
  final String name;
  final String? avatarUrl;
  final bool isActive;
  final String? lembagaName;
  final String? registrationNumber;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topInset + 12, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF002B5C)],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Positioned(
            bottom: -20,
            right: -20,
            child: Opacity(
              opacity: 0.08,
              child: Icon(
                Icons.circle_outlined,
                size: 160,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFB51B),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 13,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                child: avatarUrl == null
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Color(0xFF18233D),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : Image.network(
                        avatarUrl!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          initials,
                          style: const TextStyle(
                            color: Color(0xFF18233D),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (lembagaName != null) ...[
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    lembagaName!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (registrationNumber != null) ...[
                const SizedBox(height: 2),
                Text(
                  registrationNumber!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF7BD38C)
                      : const Color(0xFFF3B23F),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  isActive ? 'AKUN AKTIF' : 'AKUN NONAKTIF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final words =
        value.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'SL';
    if (words.length == 1) {
      final w = words.first;
      return w.substring(0, w.length < 2 ? w.length : 2).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}