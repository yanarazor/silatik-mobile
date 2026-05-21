import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(22, 0, 22, 14 + bottomInset),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2D5C).withOpacity(0.14),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            selected: selectedIndex == 0,
            onTap: () => _go(context, 0),
          ),
          _NavItem(
            icon: Icons.groups_2_outlined,
            label: 'Auditor',
            selected: selectedIndex == 1,
            onTap: () => _go(context, 1),
          ),
          _NavItem(
            icon: Icons.notifications_none_rounded,
            label: 'Notifikasi',
            selected: selectedIndex == 2,
            onTap: () => _go(context, 2),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            selected: selectedIndex == 3,
            onTap: () => _go(context, 3),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, int index) {
    final routes = [
      AppRoutes.dashboard,
      AppRoutes.auditors,
      AppRoutes.notifications,
      AppRoutes.profile,
    ];
    if (index == selectedIndex) return;
    context.push(routes[index]);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : const Color(0xFF6E7B91);
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          ],
        ),
      ),
    );
  }
}
