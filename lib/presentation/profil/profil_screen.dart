import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../data/models/faq.dart';
import '../../data/models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_menu_provider.dart';
import '../shared/menu_group.dart';
import 'widgets/app_version_footer.dart';
import 'widgets/faq_item.dart';
import 'widgets/profile_header.dart';
import 'widgets/sheet_frame.dart';
import 'widgets/sheet_row.dart';

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topInset = MediaQuery.paddingOf(context).top;
    // debugPrint('[topInset] ${topInset}');
    final user = UserProfile.fromJson(ref.watch(authProvider).user ?? const {});
    final profileAsync = ref.watch(latikProfileProvider);

    final displayName =
        user.displayName.isNotEmpty ? user.displayName : 'Pengguna SILATIK';
    final avatarUrl = user.avatarUrl;
    final isActive = user.active;
    final lembagaName = profileAsync.maybeWhen(
      data: (d) => d.namaLatik.isEmpty ? null : d.namaLatik,
      orElse: () => null,
    );
    final registrationNumber = profileAsync.maybeWhen(
      data: (d) => d.noPendaftaran.isEmpty ? null : d.noPendaftaran,
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
            ProfileHeader(
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
                  const AppVersionFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                    return SheetFrame(
                      title: title,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return SheetFrame(
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
                  return SheetFrame(
                    title: title,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: rows.entries
                          .map((e) => SheetRow(e.key, e.value))
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
              child: FutureBuilder<List<Faq>>(
                future: ref.read(faqProfileProvider.future),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SheetFrame(
                      title: 'Bantuan & Panduan',
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const SheetFrame(
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
                    return const SheetFrame(
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
                  return SheetFrame(
                    title: 'Bantuan & Panduan',
                    showClose: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < data.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: Color(0xFFE5EAF3)),
                          FaqItem(
                            title: data[i].title.isEmpty
                                ? 'Panduan ${i + 1}'
                                : data[i].title,
                            body: data[i].body,
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

  Map<String, String> _mapSettings(UserProfile user) {
    final roles = user.roleLabels;
    return {
      'Status Akun': user.active ? 'Aktif' : 'Nonaktif',
      'Role': roles.isEmpty ? '-' : roles.join(', '),
      'Permission':
          user.permissionCount == 0 ? '-' : '${user.permissionCount} akses',
      'Tipe Identitas': user.identityTypeLabel,
    };
  }
}