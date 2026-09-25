import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/user_profile.dart';
import 'field_row.dart';
import 'identity_card.dart';
import 'identity_type_row.dart';
import 'pengguna_colors.dart';
import 'role_chip.dart';
import 'section_card.dart';

/// Full user-profile body: identity card + info sections.
class UserProfileView extends StatelessWidget {
  const UserProfileView({super.key, required this.info});

  final UserProfile info;

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[];
    void addField(String label, String value, {bool mono = false}) {
      if (value.isEmpty) return;
      if (fields.isNotEmpty) {
        fields.add(const Divider(height: 1, color: penggunaCardDivider));
      }
      fields.add(FieldRow(label: label, value: value, mono: mono));
    }

    void addWidget(Widget widget) {
      if (fields.isNotEmpty) {
        fields.add(const Divider(height: 1, color: penggunaCardDivider));
      }
      fields.add(widget);
    }

    addField('Nama Lengkap', info.displayName);
    addField('Username', info.username, mono: true);
    addField('Email', info.displayEmail);
    addField('Nomor Handphone / WhatsApp', info.phone);
    addField('Nomor Identitas', info.identityNumber, mono: true);
    if (info.identityTypeLabel.isNotEmpty) {
      addWidget(IdentityTypeRow(value: info.identityTypeLabel));
    }
    addField('Jenis Kelamin', info.genderLabel);

    final accessChildren = _accessChildren(info);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        IdentityCard(info: info),
        if (fields.isNotEmpty) ...[
          const SizedBox(height: 12),
          SectionCard(title: 'Informasi Pengguna', children: fields),
        ],
        if (accessChildren.isNotEmpty) ...[
          const SizedBox(height: 12),
          SectionCard(title: 'Role & Akses', children: accessChildren),
        ],
      ],
    );
  }
}

List<Widget> _accessChildren(UserProfile info) {
  final roles = info.roleLabels;
  final permissions = info.permissionCount;
  if (roles.isEmpty && permissions == 0) return const [];

  return [
    if (roles.isNotEmpty) ...[
      const Text(
        'Role Terdaftar',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [for (final r in roles) RoleChip(label: r)],
      ),
    ],
    if (roles.isNotEmpty && permissions > 0)
      const Divider(height: 21, color: penggunaCardDivider),
    if (permissions > 0)
      Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jumlah Permission',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Total hak otorisasi akun aktif',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.key_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$permissions akses',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
  ];
}