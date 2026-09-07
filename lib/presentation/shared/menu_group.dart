import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';

class MenuItemData {
  const MenuItemData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconBgColor,
    this.iconColor,
    this.trailing,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconBgColor;
  final Color? iconColor;
  final Widget? trailing;
  final bool isDestructive;
}

class MenuGroup extends StatelessWidget {
  const MenuGroup({
    super.key,
    required this.items,
    this.margin,
  });

  final List<MenuItemData> items;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: Color(0xFFF0F2F7)),
            MenuItemRow(data: items[i]),
          ],
        ],
      ),
    );
  }
}

class MenuItemRow extends StatelessWidget {
  const MenuItemRow({super.key, required this.data});

  final MenuItemData data;

  static const _defaultIconBg = Color(0xFFE8F0FE);
  static const _defaultIconColor = AppColors.primary;
  static const _defaultDestructiveBg = Color(0xFFFDECEC);
  static const _defaultDestructiveColor = AppColors.error;

  @override
  Widget build(BuildContext context) {
    final iconBg = data.iconBgColor ??
        (data.isDestructive ? _defaultDestructiveBg : _defaultIconBg);
    final iconColor = data.iconColor ??
        (data.isDestructive ? _defaultDestructiveColor : _defaultIconColor);
    final textColor =
        data.isDestructive ? AppColors.error : AppColors.textPrimary;

    return InkWell(
      onTap: data.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(data.icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            data.trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: data.isDestructive
                      ? AppColors.error.withValues(alpha: 0.5)
                      : const Color(0xFFA7B0C3),
                ),
          ],
        ),
      ),
    );
  }
}
