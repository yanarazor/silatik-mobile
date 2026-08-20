import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_menu_provider.dart';
import '../../providers/registrasi_provider.dart';

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topInset = MediaQuery.paddingOf(context).top;
    final user = ref.watch(authProvider).user;
    final displayName = _stringValue(user, 'first_name') ??
        _stringValue(user, 'username') ??
        'Pengguna SILATIK';
    final email = _stringValue(user, 'email') ??
        _stringValue(user, 'username') ??
        _stringValue(user, 'external_email') ??
        '-';
    final avatarUrl =
        _stringValue(user, 'avatar_url') ?? _stringValue(user, 'photo_url');
    final isActive = user?['active'] == 1 || user?['active'] == true;

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 700 + topInset,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 260 + topInset,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF004CA5),
                          Color(0xFF003676),
                        ],
                      ),
                    ),
                    child: _ProfileHeader(
                      topInset: topInset,
                      name: displayName,
                      email: email,
                      avatarUrl: avatarUrl,
                      isActive: isActive,
                    ),
                  ),
                  Positioned(
                    top: 230 + topInset,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                      ),
                      child: Column(
                        children: [
                          _ProfileMenuItem(
                            icon: Icons.apartment_outlined,
                            title: 'Profil Lembaga',
                            onTap: () => _showLatikProfileSheet(
                              context,
                              ref,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ProfileMenuItem(
                            icon: Icons.person_outline_rounded,
                            title: 'Pengguna',
                            onTap: () => _showApiInfoSheet(
                              context,
                              title: 'Pengguna',
                              future: ref.refresh(userProfileProvider.future),
                              mapper: _mapUserProfile,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ProfileMenuItem(
                            icon: Icons.settings_outlined,
                            title: 'Pengaturan',
                            onTap: () => _showApiInfoSheet(
                              context,
                              title: 'Pengaturan',
                              future: ref.refresh(userProfileProvider.future),
                              mapper: _mapSettings,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ProfileMenuItem(
                            icon: Icons.help_outline_rounded,
                            title: 'Bantuan & Panduan',
                            onTap: () =>
                                _showApiInfoSheet<List<Map<String, dynamic>>>(
                              context,
                              title: 'Bantuan & Panduan',
                              future: ref.refresh(faqProfileProvider.future),
                              mapper: _mapFaqs,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _ProfileMenuItem(
                            icon: Icons.logout_rounded,
                            title: 'Keluar',
                            isLogout: true,
                            onTap: () async {
                              await ref.read(authProvider.notifier).logout();
                              if (!context.mounted) return;
                              context.go(AppRoutes.login);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _stringValue(Map<String, dynamic>? data, String key) {
    final value = data?[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
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
                            color: Color(0xFFE53935),
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
                          .map((entry) => _SheetRow(entry.key, entry.value))
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

  void _showLatikProfileSheet(BuildContext context, WidgetRef ref) {
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
              child: FutureBuilder<Map<String, dynamic>>(
                future: ref.refresh(latikProfileProvider.future),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return _SheetFrame(
                      title: 'Profil Lembaga',
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return _SheetFrame(
                      title: 'Profil Lembaga',
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Gagal memuat data dari API.',
                          style: TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data!;
                  final rows = _mapLatikProfile(data);
                  return _SheetFrame(
                    title: 'Profil Lembaga',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...rows.entries
                            .map((entry) => _SheetRow(entry.key, entry.value))
                            .toList(),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () =>
                              _showLatikEditSheet(context, ref, data),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit Profil Lembaga'),
                        ),
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

  void _showLatikEditSheet(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
  ) {
    final nameCtrl = TextEditingController(
        text: _value(data, const ['name', 'nama', 'nama_latik']));
    final nibCtrl = TextEditingController(
        text: _value(data, const ['no_nib', 'nib', 'nomor_nib']));
    final emailCtrl = TextEditingController(
        text: _value(data, const ['email', 'email_latik']));
    final phoneCtrl = TextEditingController(
        text: _value(data, const ['phone', 'telepon', 'no_hp']));
    final addressCtrl =
        TextEditingController(text: _value(data, const ['address', 'alamat']));
    final refLatik = _value(data, const ['ref', 'latik_ref', 'ref_latik']);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              18,
              22,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Profil Lembaga',
                  style: TextStyle(
                    color: Color(0xFF0C2D5C),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Lembaga'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nibCtrl,
                  decoration: const InputDecoration(labelText: 'NIB'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Telepon'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                  maxLines: 2,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () async {
                    final payload = <String, dynamic>{
                      if (refLatik.isNotEmpty) 'ref': refLatik,
                      'name': nameCtrl.text.trim(),
                      'no_nib': nibCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'address': addressCtrl.text.trim(),
                    };
                    try {
                      await ref
                          .read(latikServiceProvider)
                          .updateProfile(payload);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Profil lembaga diperbarui')),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Gagal memperbarui profil')),
                        );
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, String> _mapLatikProfile(Map<String, dynamic> data) {
    return {
      'Nama': _value(data, const ['nama', 'name', 'nama_latik', 'first_name']),
      'NIB': _value(data, const ['nib', 'nomor_nib', 'no_nib']),
      'Email': _value(data, const ['email', 'email_latik']),
      'Telepon': _value(data, const ['telepon', 'phone', 'no_hp']),
      'Alamat': _value(data, const ['alamat', 'address']),
      'Status': _value(data, const ['status', 'status_verifikasi', 'active']),
    };
  }

  Map<String, String> _mapUserProfile(Map<String, dynamic> data) {
    return {
      'Nama': _value(data, const ['first_name', 'name', 'nama']),
      'Username': _value(data, const ['username']),
      'Email': _value(data, const ['email', 'external_email']),
      'No. HP': _value(data, const ['phone', 'no_hp']),
      'Role': _rolesText(data),
    };
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

  Map<String, String> _mapFaqs(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const {'FAQ': 'Belum ada panduan aktif dari API.'};
    }
    return {
      for (var i = 0; i < data.length && i < 5; i++)
        _value(data[i], const ['title', 'judul', 'question', 'pertanyaan'],
            fallback: 'Panduan ${i + 1}'): _stripHtml(_value(data[i], const [
          'body',
          'isi',
          'answer',
          'jawaban',
          'description'
        ])),
    };
  }

  String _value(Map<String, dynamic> data, List<String> keys,
      {String fallback = '-'}) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null')
        return text; // This line remains unchanged
    }
    return fallback;
  }

  String _rolesText(Map<String, dynamic> data) {
    final roles = data['roles'];
    if (roles is List && roles.isNotEmpty) {
      return roles.map((role) {
        if (role is Map)
          return (role['name'] ?? role['description'] ?? role).toString();
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

  String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});

  final String title;
  final Widget child;

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
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0C2D5C),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
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
              color: Color(0xFF6E7B91),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF243552),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.topInset,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.isActive,
  });

  final double topInset;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);

    return Column(
      children: [
        SizedBox(height: topInset + 32),
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFB51B),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
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
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : Image.network(
                  avatarUrl!,
                  width: 82,
                  height: 82,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF18233D),
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.78),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF7BD38C) : const Color(0xFFF3B23F),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            isActive ? 'AKUN AKTIF' : 'AKUN NONAKTIF',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'SL';
    if (words.length == 1) {
      final word = words.first;
      return word.substring(0, word.length < 2 ? word.length : 2).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLogout = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLogout;

  @override
  Widget build(BuildContext context) {
    final color = isLogout ? const Color(0xFFE53935) : const Color(0xFF4A5876);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5EAF3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isLogout
                        ? const Color(0xFFE53935)
                        : const Color(0xFF243552),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!isLogout)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFA7B0C3),
                  size: 23,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
