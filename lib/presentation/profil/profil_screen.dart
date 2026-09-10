import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/api_response_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_menu_provider.dart';
import '../shared/menu_group.dart';

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topInset = MediaQuery.paddingOf(context).top;
    // debugPrint('[topInset] ${topInset}');
    final user = ref.watch(authProvider).user;
    final profileAsync = ref.watch(latikProfileProvider);

    final displayName = _stringValue(user, 'first_name') ??
        _stringValue(user, 'username') ??
        'Pengguna SILATIK';
    final avatarUrl = profileAsync.maybeWhen(
          data: (d) => _stringValue(d, 'photo'),
          orElse: () => null,
        ) ??
        _stringValue(user, 'avatar_url') ??
        _stringValue(user, 'photo_url');
    final isActive = user?['active'] == 1 || user?['active'] == true;
    final lembagaName = profileAsync.maybeWhen(
      data: (d) => _value(d, const ['nama', 'name', 'nama_latik']),
      orElse: () => null,
    );
    final registrationNumber = profileAsync.maybeWhen(
      data: (d) => _value(d, const [
        'no_pendaftaran',
        'nomor_registrasi',
        'registration_number',
      ]),
      orElse: () => null,
    );

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            _ProfileHeader(
              topInset: topInset,
              name: displayName,
              avatarUrl: avatarUrl,
              isActive: isActive,
              lembagaName: lembagaName,
              registrationNumber: registrationNumber,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  MenuGroup(
                    items: [
                      MenuItemData(
                        icon: Icons.apartment_outlined,
                        label: 'Profil Lembaga',
                        onTap: () => context.push(AppRoutes.profilLembaga),
                      ),
                      MenuItemData(
                        icon: Icons.person_outline_rounded,
                        label: 'Data Pengguna',
                        onTap: () => context.push(AppRoutes.dataPengguna),
                      ),
                      MenuItemData(
                        icon: Icons.description_outlined,
                        label: 'Dokumen & Berkas',
                        onTap: () => context.push(AppRoutes.dokumenBerkas),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  MenuGroup(
                    items: [
                      MenuItemData(
                        icon: Icons.help_outline_rounded,
                        label: 'Pusat Bantuan',
                        iconBgColor: const Color(0xFFF3F4F6),
                        iconColor: AppColors.textSecondary,
                        onTap: () => _showFaqSheet(context, ref),
                      ),
                      MenuItemData(
                        icon: Icons.settings_outlined,
                        label: 'Pengaturan',
                        iconBgColor: const Color(0xFFF3F4F6),
                        iconColor: AppColors.textSecondary,
                        onTap: () => _showApiInfoSheet(
                          context,
                          title: 'Pengaturan',
                          future: ref.read(userProfileProvider.future),
                          mapper: _mapSettings,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  MenuGroup(
                    items: [
                      MenuItemData(
                        icon: Icons.logout_rounded,
                        label: 'Keluar',
                        isDestructive: true,
                        trailing: const SizedBox.shrink(),
                        onTap: () => _confirmLogout(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _AppVersionFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _stringValue(Map<String, dynamic>? data, String key) =>
      data == null ? null : meaningfulString(data[key]);

  static String _value(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '-',
  }) =>
      pickString(data, keys, fallback: fallback)!;

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text('Yakin ingin keluar dari akun?'),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(true),
                child: const Text('Keluar'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) context.go(AppRoutes.login);
  }

  void _showApiInfoSheet<T>(
    BuildContext context, {
    required String title,
    required Future<T> future,
    required Map<String, String> Function(T data) mapper,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.78,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              child: FutureBuilder<T>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return _SheetFrame(
                      title: title,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return _SheetFrame(
                      title: title,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Gagal memuat data dari API.',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  }
                  final rows = mapper(snapshot.data as T);
                  return _SheetFrame(
                    title: title,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: rows.entries
                          .map((e) => _SheetRow(e.key, e.value))
                          .toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFaqSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: ref.read(faqProfileProvider.future),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const _SheetFrame(
                      title: 'Bantuan & Panduan',
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const _SheetFrame(
                      title: 'Bantuan & Panduan',
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Gagal memuat data dari API.',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  }
                  final data = snapshot.data!;
                  if (data.isEmpty) {
                    return const _SheetFrame(
                      title: 'Bantuan & Panduan',
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Belum ada panduan aktif dari API.',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }
                  return _SheetFrame(
                    title: 'Bantuan & Panduan',
                    showClose: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < data.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: Color(0xFFE5EAF3)),
                          _FaqItem(
                            title: _value(
                                data[i],
                                const [
                                  'title',
                                  'judul',
                                  'question',
                                  'pertanyaan',
                                ],
                                fallback: 'Panduan ${i + 1}'),
                            body: _value(data[i], const [
                              'body',
                              'isi',
                              'answer',
                              'jawaban',
                              'description',
                            ]),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, String> _mapSettings(Map<String, dynamic> data) {
    return {
      'Status Akun': _value(data, const ['active']) == '1' ||
              _value(data, const ['active']).toLowerCase() == 'true'
          ? 'Aktif'
          : 'Nonaktif',
      'Role': _rolesText(data),
      'Permission': _permissionsCount(data),
      'Tipe Identitas': _value(data, const ['identity_type']),
    };
  }

  String _rolesText(Map<String, dynamic> data) {
    final roles = data['roles'];
    if (roles is List && roles.isNotEmpty) {
      return roles.map((role) {
        if (role is Map) {
          return (role['name'] ?? role['description'] ?? role).toString();
        }
        return role.toString();
      }).join(', ');
    }
    return '-';
  }

  String _permissionsCount(Map<String, dynamic> data) {
    final permissions = data['permissions'] ?? data['permission'];
    if (permissions is List) return '${permissions.length} akses';
    return '-';
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
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

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.child,
    this.showClose = false,
  });

  final String title;
  final Widget child;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5EAF3),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (showClose)
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                color: AppColors.textSecondary,
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({required this.title, required this.body});

  final String title;
  final String body;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: HtmlWidget(
                  widget.body,
                  textStyle: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppVersionFooter extends StatelessWidget {
  const _AppVersionFooter();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final year = DateTime.now().year;

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '...';
        // final buildNumber = snapshot.data?.buildNumber ?? '';
        return Column(
          children: [
            Text('Versi $version (Mobile)', style: style),
            const SizedBox(height: 4),
            Text(
              '© $year | Direktorat Alih dan Sistem Audit Teknologi',
              style: style,
            ),
          ],
        );
      },
    );
  }
}
