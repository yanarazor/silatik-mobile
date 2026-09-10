import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/api_response_utils.dart';
import '../../providers/profile_menu_provider.dart';

const _cardBorder = Color(0xFFE5EAF3);
const _cardDivider = Color(0xFFF0F2F7);
const _activeColor = Color(0xFF25B45B);
const _inactiveColor = Color(0xFFE8A000);
const _avatarBg = Color(0xFFFFB51B);
const _avatarInk = Color(0xFF18233D);
const _chipBg = Color(0xFFEBF3FA);
const _chipBorder = Color(0xFFD5E5F7);

class DataPenggunaScreen extends ConsumerWidget {
  const DataPenggunaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Data Pengguna'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Gagal memuat data pengguna.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(userProfileProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (data) => _UserProfileView(data: data),
      ),
    );
  }
}

class _UserProfileView extends StatelessWidget {
  const _UserProfileView({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final info = _UserData(data);
    final fields = <Widget>[];
    void addField(String label, String value, {bool mono = false}) {
      if (value.isEmpty) return;
      if (fields.isNotEmpty) {
        fields.add(const Divider(height: 1, color: _cardDivider));
      }
      fields.add(_FieldRow(label: label, value: value, mono: mono));
    }

    void addWidget(Widget widget) {
      if (fields.isNotEmpty) {
        fields.add(const Divider(height: 1, color: _cardDivider));
      }
      fields.add(widget);
    }

    addField('Nama Lengkap', info.name);
    addField('Username', info.username, mono: true);
    addField('Email', info.email);
    addField('Nomor Handphone / WhatsApp', info.phone);
    addField('Nomor Identitas', info.identityNumber, mono: true);
    if (info.identityType.isNotEmpty) {
      addWidget(_IdentityTypeRow(value: info.identityType));
    }
    addField('Jenis Kelamin', info.gender);

    final accessChildren = info.accessChildren();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _IdentityCard(info: info),
        if (fields.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(title: 'Informasi Pengguna', children: fields),
        ],
        if (accessChildren.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(title: 'Role & Akses', children: accessChildren),
        ],
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.info});

  final _UserData info;

  @override
  Widget build(BuildContext context) {
    final statusColor = info.isActive ? _activeColor : _inactiveColor;
    final avatarUrl = info.avatarUrl;
    final initials = info.initials;
    const initialsStyle = TextStyle(
      color: _avatarInk,
      fontSize: 24,
      fontWeight: FontWeight.w800,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _avatarBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _avatarBg.withValues(alpha: 0.25),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                child: avatarUrl == null
                    ? Text(initials, style: initialsStyle)
                    : Image.network(
                        avatarUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Text(initials, style: initialsStyle),
                      ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            info.fullName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          if (info.email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              info.email,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              info.isActive ? 'AKUN AKTIF' : 'AKUN NONAKTIF',
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
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
    this.mono = false,
  });

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
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
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: mono ? 'monospace' : null,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityTypeRow extends StatelessWidget {
  const _IdentityTypeRow({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipe Identitas',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.badge_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    final IconData icon;
    if (lower.contains('auditor') ||
        lower.contains('akreditasi') ||
        lower.contains('pic')) {
      icon = Icons.verified_user_rounded;
    } else if (lower.contains('latik') || lower.contains('operator')) {
      icon = Icons.security_rounded;
    } else {
      icon = Icons.badge_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _chipBg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
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
}

class _UserData {
  _UserData(this.data);

  final Map<String, dynamic> data;

  String get name {
    final first = _pick(const ['first_name', 'name', 'full_name', 'nama']);
    final last = _pick(const ['last_name']);
    if (first.isEmpty) return last;
    if (last.isEmpty) return first;
    return '$first $last';
  }

  String get fullName {
    if (name.isNotEmpty) return name;
    return username.isNotEmpty ? username : '-';
  }

  String? get avatarUrl {
    final url = _pick(const ['photo_url', 'avatar_url']);
    return url.isEmpty ? null : url;
  }

  String get username => _pick(const ['username']);

  String get email => _pick(const ['email', 'external_email']);

  String get phone =>
      _pick(const ['phone', 'no_hp', 'no_hp_wa', 'handphone']);

  String get identityNumber =>
      _pick(const ['identity_number', 'no_identitas', 'nomor_identitas', 'nik']);

  String get identityType {
    final value = data['identity_type'];
    return identityTypeFromRaw(value)?.label ?? '';
  }

  String get gender {
    final value = data['sex'];
    return genderFromRaw(value)?.label ?? '';
  }

  bool get isActive {
    final value = data['active'];
    return value == 1 || value == true || value == '1';
  }

  String get initials {
    final words =
        fullName.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'SL';
    if (words.length == 1) {
      final w = words.first;
      return w.substring(0, w.length < 2 ? w.length : 2).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  List<String> get roles {
    final raw = data['roles'];
    if (raw is! List) return const [];
    final roles = <String>[];
    for (final role in raw) {
      if (role is Map) {
        final name = (role['name'] ?? role['role_name'] ?? '').toString();
        final label = name.trim().isNotEmpty
            ? name
            : (role['description'] ?? '').toString();
        if (label.trim().isNotEmpty) roles.add(label.trim());
      } else if (role != null && role.toString().trim().isNotEmpty) {
        roles.add(role.toString().trim());
      }
    }
    return roles;
  }

  int? get permissionCount {
    final raw = data['permissions'] ?? data['permission'];
    if (raw is List) return raw.length;
    return null;
  }

  List<Widget> accessChildren() {
    final roles = this.roles;
    final permissions = permissionCount;
    if (roles.isEmpty && permissions == null) return const [];

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
          children: [for (final r in roles) _RoleChip(label: r)],
        ),
      ],
      if (roles.isNotEmpty && permissions != null)
        const Divider(height: 21, color: _cardDivider),
      if (permissions != null)
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

  String _pick(List<String> keys) => pickString(data, keys, fallback: '')!;
}
