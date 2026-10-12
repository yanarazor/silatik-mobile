import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/cache_utils.dart';
import '../../core/utils/file_utils.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/user_profile.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/profile_menu_provider.dart';
import 'widgets/app_version_footer.dart';
import 'widgets/pengaturan/settings_section.dart';

class PengaturanScreen extends ConsumerWidget {
  const PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          SettingsSection(
            title: 'TAMPILAN',
            rows: [
              SettingsRow(
                icon: Icons.dark_mode_outlined,
                label: 'Mode Gelap',
                subtitle: 'Segera hadir',
                trailing: Switch(
                  value: settings.darkMode,
                  onChanged: notifier.setDarkMode,
                ),
              ),
              SettingsRow(
                icon: Icons.translate_rounded,
                label: 'Bahasa',
                trailing: _ValueLabel(settings.language.label),
                onTap: () => _pickLanguage(context, ref, settings.language),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SettingsSection(
            title: 'NOTIFIKASI',
            rows: [
              SettingsRow(
                icon: Icons.notifications_outlined,
                label: 'Notifikasi',
                trailing: Switch(
                  value: settings.notificationsEnabled,
                  onChanged: notifier.setNotificationsEnabled,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SettingsSection(
            title: 'AKUN',
            rows: _accountRows(profileAsync),
          ),
          const SizedBox(height: 18),
          SettingsSection(
            title: 'UMUM',
            rows: [
              SettingsRow(
                icon: Icons.cleaning_services_outlined,
                label: 'Bersihkan Cache',
                onTap: () => _confirmClearCache(context),
              ),
              SettingsRow(
                icon: Icons.star_outline_rounded,
                label: 'Beri Rating Aplikasi',
                onTap: () => _rateApp(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<SettingsRow> _accountRows(AsyncValue<UserProfile> profileAsync) {
    final user = profileAsync.valueOrNull;
    return [
      SettingsRow(
        icon: Icons.verified_user_outlined,
        label: 'Status Akun',
        trailing: _ValueLabel(
          user == null ? '-' : (user.active ? 'Aktif' : 'Nonaktif'),
        ),
      ),
      SettingsRow(
        icon: Icons.badge_outlined,
        label: 'Role',
        trailing: _ValueLabel(_roles(user)),
      ),
      SettingsRow(
        icon: Icons.key_outlined,
        label: 'Permission',
        trailing: _ValueLabel(
          user == null || user.permissionCount == 0
              ? '-'
              : '${user.permissionCount} akses',
        ),
      ),
    ];
  }

  String _roles(UserProfile? user) {
    final roles = user?.roleLabels ?? const [];
    return roles.isEmpty ? '-' : roles.join(', ');
  }

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    AppLanguage current,
  ) async {
    final picked = await showModalBottomSheet<AppLanguage>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Pilih Bahasa',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            RadioGroup<AppLanguage>(
              groupValue: current,
              onChanged: (value) => Navigator.pop(context, value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final lang in AppLanguage.values)
                    RadioListTile<AppLanguage>(
                      value: lang,
                      title: Text(lang.label),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref.read(appSettingsProvider.notifier).setLanguage(picked);
    }
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bersihkan Cache'),
            content: const Text(
              'Menghapus berkas sementara dan gambar yang tersimpan. '
              'Data akun tidak terpengaruh.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Bersihkan'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok || !context.mounted) return;

    final freed = await CacheUtils.clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          freed == 0
              ? 'Cache sudah bersih'
              : 'Cache dibersihkan (${FileUtils.formatBytes(freed)})',
        ),
      ),
    );
  }

  Future<void> _rateApp(BuildContext context) async {
    // TODO(settings): point at the real listing id once the app is published.
    final uri = Uri.parse('market://details?id=com.brin.silatik');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka toko aplikasi')),
      );
    }
  }
}

class _ValueLabel extends StatelessWidget {
  const _ValueLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
