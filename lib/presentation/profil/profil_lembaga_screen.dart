import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/api_response_utils.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auditor_provider.dart';
import '../../providers/profile_menu_provider.dart';
import '../../providers/registrasi_provider.dart';

const _green = Color(0xFF25B45B);
const _amber = Color(0xFFE8A000);
const _cardBorder = Color(0xFFE5EAF3);
const _blueTint = Color(0xFFEAF2FB);
const _blueTintBorder = Color(0xFFD5E5F7);
const _scopeBg = Color(0xFFEBF3FC);

class ProfilLembagaScreen extends ConsumerWidget {
  const ProfilLembagaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(latikProfileProvider);
    final auditorCount =
        ref.watch(auditorListProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Profil Lembaga'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Gagal memuat data profil.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(latikProfileProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (data) {
          if (!_hasProfileData(data)) {
            return _EmptyProfileState(
              onRetry: () => ref.invalidate(latikProfileProvider),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              _IdentityCard(data: data),
              const SizedBox(height: 12),
              _StatsRow(data: data, auditorCount: auditorCount),
              const SizedBox(height: 16),
              _InfoSection(data: data),
            ],
          );
        },
      ),
      bottomNavigationBar: profileAsync.maybeWhen(
        data: (data) => _EditFooter(
          onEdit: () => _showEditSheet(context, ref, data),
        ),
        orElse: () => null,
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
  ) {
    final nameCtrl = TextEditingController(
        text: _deepPick(data, const ['name', 'nama', 'nama_latik']));
    final nibCtrl = TextEditingController(
        text: _deepPick(
            data, const ['no_nib', 'nib', 'nomor_nib', 'no_nib_latik']));
    final emailCtrl = TextEditingController(
        text:
            _deepPick(data, const ['email', 'email_latik', 'email_institusi']));
    final phoneCtrl = TextEditingController(
        text: _deepPick(
            data, const ['phone', 'telepon', 'no_hp', 'telepon_kantor']));
    final addressCtrl = TextEditingController(
        text: _deepPick(data, const ['address', 'alamat', 'alamat_latik']));
    final refLatik = _deepPick(data, const ['ref', 'latik_ref', 'ref_latik']);

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Edit Profil Lembaga',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nama Lembaga'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nibCtrl,
                    decoration: const InputDecoration(labelText: 'NIB'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Telepon'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: 'Alamat'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
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
                        ref.invalidate(latikProfileProvider);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Profil lembaga diperbarui')),
                        );
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
          ),
        );
      },
    );
  }
}

class _EmptyProfileState extends StatelessWidget {
  const _EmptyProfileState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
        children: [
          Icon(
            Icons.apartment_outlined,
            size: 56,
            color: AppColors.primary.withValues(alpha: 0.65),
          ),
          const SizedBox(height: 16),
          const Text(
            'Profil lembaga belum tersedia',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Data profil belum dikirim oleh server. Tarik layar untuk memuat ulang.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}

class _DebugDataBanner extends StatelessWidget {
  const _DebugDataBanner({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final keys = data.keys
        .where((k) => data[k] != null && data[k].toString().trim().isNotEmpty)
        .toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEBUG: Profile keys (${keys.length})',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            keys.take(20).join(', '),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _EditFooter extends StatelessWidget {
  const _EditFooter({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4ECF7))),
        boxShadow: [
          BoxShadow(
            color: Color(0x140C2D5C),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 20),
            label: const Text('Edit Profil Lembaga'),
          ),
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final nama = _text(_deepPick(data, const [
      'nama_latik',
      'nama_latik_perusahaan',
      'name',
      'nama',
      'first_name'
    ]));
    final regNumber = _text(_deepPick(data, const [
      'no_pendaftaran',
      'nomor_registrasi',
      'no_registrasi',
      'registration_number',
      'kode_registrasi',
      'kode_register',
      'no_register',
      'nomor_register',
      'registration_code',
      'no_urut_ext',
      'no_urut'
    ]));
    final str = _strInfo(data);
    final badges = _statusBadges(data, str);

    final displayName = nama.isEmpty ? 'Nama Lembaga Belum Diisi' : nama;
    final displayReg = regNumber.isEmpty ? 'Belum Terdaftar' : regNumber;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _blueTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _blueTintBorder),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.tag,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            displayReg,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final b in badges.isEmpty
                            ? [const _PillSpec('Belum Terverifikasi', _amber)]
                            : badges)
                          _Pill(spec: b),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (str != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: Color(0xFFF0F2F7)),
            ),
            _StrCard(info: str),
          ],
        ],
      ),
    );
  }
}

class _StrCard extends StatelessWidget {
  const _StrCard({required this.info});

  final _StrInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAF2FB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Surat Tanda Registrasi (STR)',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              _Pill(spec: info.statusSpec),
            ],
          ),
          const SizedBox(height: 4),
          _PairRow(
            label: 'No. STR',
            value: info.no,
            mono: true,
          ),
          if (info.period.isNotEmpty)
            _PairRow(
              label: 'Masa Berlaku',
              value: info.period,
            ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.data, required this.auditorCount});

  final Map<String, dynamic> data;
  final int auditorCount;

  @override
  Widget build(BuildContext context) {
    final count = _intValue(data, const [
          'jumlah_auditor',
          'total_auditor',
          'jumlah',
          'total_auditors',
          'auditor_count'
        ]) ??
        auditorCount;

    final akreditasiText = _text(_deepPick(data, const [
      'nama_status_kan',
      'status_akreditasi_kan',
      'status_kan',
      'akreditasi_kan',
      'status_akreditasi'
    ]));
    final punyaKan = _deepPick(data, const [
      'nomor_kan',
      'no_kan',
      'nomor_sertifikat_kan',
      'nomor_sertifikat',
      'file_cer_kan',
      'file_kan',
      'sertifikat_kan',
      'file_sertifikat_kan',
      'ruang_lingkup_kan',
      'ruang_lingkup_akreditasi'
    ]).isNotEmpty;
    final akreditasiValue = akreditasiText.isNotEmpty
        ? akreditasiText
        : (punyaKan ? 'Terdaftar' : '-');

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            iconBg: _blueTint,
            iconColor: AppColors.primary,
            icon: Icons.group_rounded,
            label: 'Total Auditor',
            value: '$count Orang',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            iconBg: _green.withValues(alpha: 0.12),
            iconColor: _green,
            icon: Icons.verified_rounded,
            label: 'Akreditasi KAN',
            value: akreditasiValue,
            valueColor: akreditasiValue == 'Terdaftar' ? _green : null,
          ),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();

    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SizedBox(
                width: 4,
                height: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Informasi Lembaga',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: const Text(
                'Belum ada data informasi lembaga.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: Color(0xFFF0F2F7)),
              rows[i],
            ],
        ],
      ),
    );
  }

  List<Widget> _buildRows() {
    final nama = _text(_deepPick(data, const [
      'nama_latik',
      'nama_latik_perusahaan',
      'name',
      'nama',
      'first_name'
    ]));
    final email = _text(
        _deepPick(data, const ['email', 'email_latik', 'email_institusi']));
    final telepon = _text(
        _deepPick(data, const ['telepon', 'phone', 'no_hp', 'telepon_kantor']));
    final alamat = _fullAddress(data);
    final website = _text(_deepPick(
        data, const ['website', 'url_website', 'situs', 'website_latik']));
    final npwp = _text(
        _deepPick(data, const ['npwp', 'nomor_npwp', 'no_npwp', 'npwp_latik']));
    final nib = _text(
        _deepPick(data, const ['no_nib_latik', 'nib', 'nomor_nib', 'no_nib']));
    final scopes = latikScopeLabels(data['lingkup_pendaftaran'] ??
        data['ruang_lingkup_latik'] ??
        data['ruang_lingkup'] ??
        data['scope']);

    final rows = <Widget>[];
    if (nama.isNotEmpty) {
      rows.add(_ValueRow(label: 'Nama Lembaga', value: nama));
    }
    if (email.isNotEmpty) {
      rows.add(_ValueRow(
        label: 'Email Institusi',
        value: email,
        valueColor: AppColors.primaryLight,
        onTap: () => _launchUrl(email, mailto: true),
      ));
    }
    if (telepon.isNotEmpty) {
      rows.add(_ValueRow(label: 'Nomor Telepon Kantor', value: telepon));
    }
    if (alamat.isNotEmpty) {
      rows.add(_ValueRow(label: 'Alamat Lengkap', value: alamat));
    }
    if (website.isNotEmpty) {
      rows.add(_ValueRow(
        label: 'Website Resmi',
        value: website,
        valueColor: AppColors.primaryLight,
        trailing: const Icon(Icons.open_in_new,
            size: 13, color: AppColors.primaryLight),
        onTap: () => _launchUrl(website),
      ));
    }
    if (npwp.isNotEmpty) {
      rows.add(_ValueRow(label: 'NPWP Institusi', value: npwp, mono: true));
    }
    if (nib.isNotEmpty) {
      rows.add(_ValueRow(
        label: 'Nomor Induk Berusaha (NIB)',
        value: nib,
        mono: true,
        trailing: const Icon(Icons.verified_rounded,
            size: 16, color: Color(0xFF25B45B)),
      ));
    }
    if (scopes.isNotEmpty) {
      rows.add(_ValueRow(
        label: 'Lingkup Pendaftaran',
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in scopes) _ScopeChip(label: s),
          ],
        ),
      ));
    }
    return rows;
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
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
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
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
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor ?? AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    this.value,
    this.child,
    this.valueColor,
    this.mono = false,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String? value;
  final Widget? child;
  final Color? valueColor;
  final bool mono;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = value ?? '';
    final content = child ??
        Text(
          text,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: mono ? 'monospace' : null,
            height: 1.35,
          ),
        );

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: content),
        if (trailing != null) ...[
          const SizedBox(width: 6),
          trailing!,
        ],
      ],
    );

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
          onTap != null
              ? InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: row,
                  ),
                )
              : row,
        ],
      ),
    );
  }
}

class _PairRow extends StatelessWidget {
  const _PairRow({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: mono ? 'monospace' : null,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _scopeBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _blueTintBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _scopeIcon(label),
            size: 14,
            color: AppColors.primary,
          ),
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

  static IconData _scopeIcon(String label) {
    final t = label.toLowerCase();
    if (t.contains('aplikasi')) return Icons.apps_rounded;
    if (t.contains('infrastruktur')) return Icons.lan_rounded;
    if (t.contains('keamanan')) return Icons.security_rounded;
    return Icons.apartment_rounded;
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.spec});

  final _PillSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: spec.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: spec.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: spec.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            spec.label,
            style: TextStyle(
              color: spec.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillSpec {
  const _PillSpec(this.label, this.color);

  final String label;
  final Color color;
}

class _StrInfo {
  const _StrInfo({
    required this.no,
    required this.start,
    required this.end,
    required this.period,
    required this.statusSpec,
  });

  final String no;
  final DateTime? start;
  final DateTime? end;
  final String period;
  final _PillSpec statusSpec;
}

// ponytail: status/semantics diturunkan dari teks+kode (lihat enums.dart);
// kalau backend mengirim status yang belum dikenal, label kembali ke teks aslinya.
_StrInfo? _strInfo(Map<String, dynamic> data) {
  final no = _text(
      _deepPick(data, const ['nomor_str', 'no_str', 'str_number', 'str_no']));
  final rawStart = _deepPick(data, const [
    'str_tanggal_awal',
    'tgl_terbit_str',
    'tanggal_terbit_str',
    'tanggal_terbit',
    'str_mulai',
    'berlaku_mulai'
  ]);
  final rawEnd = _deepPick(data, const [
    'str_tanggal_akhir',
    'tgl_berakhir_str',
    'tanggal_berakhir_str',
    'tanggal_berakhir',
    'masa_berlaku_sampai',
    'expired_at',
    'str_akhir',
    'berlaku_sampai'
  ]);
  final start = _date(rawStart);
  final end = _date(rawEnd);
  if (no.isEmpty && start == null && end == null) return null;

  final expired = end != null && !end.isAfter(DateTime.now());
  final rawStatus = _deepPick(data, const [
    'str_status',
    'status_str',
    'nama_status_str',
    'status_aktif_str'
  ]).toLowerCase();
  final isNonaktif = expired ||
      rawStatus.contains('nonaktif') ||
      rawStatus.contains('kadaluarsa') ||
      rawStatus.contains('expired') ||
      rawStatus.contains('dicabut') ||
      rawStatus == '0';
  final isActive = !isNonaktif &&
      (rawStatus.isEmpty ||
          rawStatus == '1' ||
          rawStatus == '4' ||
          rawStatus.contains('aktif') ||
          rawStatus.contains('valid') ||
          rawStatus.contains('publish'));

  final _PillSpec statusSpec;
  if (expired) {
    statusSpec = const _PillSpec('Kadaluarsa', AppColors.error);
  } else if (isActive) {
    statusSpec = const _PillSpec('Aktif', _green);
  } else {
    statusSpec = const _PillSpec('Nonaktif', _amber);
  }

  final period = _periodText(start, end);
  return _StrInfo(
    no: no.isEmpty ? '-' : no,
    start: start,
    end: end,
    period: period,
    statusSpec: statusSpec,
  );
}

const _registrationStatusKeys = [
  'nama_status',
  'nama_status_str',
  'status_verifikasi',
  'status',
  'status_latik',
  'verification_status',
];

// ponytail: status/semantik diturunkan dari teks+kode (mirror enums.dart);
// status baru yang tak dikenal jatuh ke label teks apa adanya.
List<_PillSpec> _statusBadges(Map<String, dynamic> data, _StrInfo? str) {
  if (str?.statusSpec.label == 'Aktif') {
    return const [
      _PillSpec('Terverifikasi', _green),
      _PillSpec('Valid', _green),
    ];
  }
  final rawStatus =
      _deepPick(data, _registrationStatusKeys).trim().toLowerCase();
  if (rawStatus.isNotEmpty &&
      (rawStatus == '4' ||
          rawStatus.contains('aktif') ||
          rawStatus.contains('terverifikasi') ||
          rawStatus.contains('approved') ||
          rawStatus.contains('valid'))) {
    return const [
      _PillSpec('Terverifikasi', _green),
      _PillSpec('Valid', _green),
    ];
  }
  final label = _statusLabel(rawStatus);
  if (label == null) {
    return const [_PillSpec('Belum Terverifikasi', _amber)];
  }
  final rejected = rawStatus.contains('dikembalikan') ||
      rawStatus.contains('ditolak') ||
      rawStatus.contains('dicabut') ||
      rawStatus.contains('kadaluarsa') ||
      rawStatus.contains('expired') ||
      rawStatus == '2';
  return [_PillSpec(label, rejected ? AppColors.error : _amber)];
}

String? _statusLabel(String rawStatus) {
  if (rawStatus.isEmpty) return null;
  const codeMap = {
    '0': 'Registrasi',
    '1': 'Proses Verifikasi',
    '2': 'Dikembalikan',
    '3': 'Penerbitan STR',
    '4': 'Aktif',
    '5': 'Kadaluarsa',
    '6': 'Dibekukan',
    '7': 'Dicabut',
    '8': 'Menunggu Pembayaran',
  };
  final byCode = codeMap[rawStatus];
  if (byCode != null) return byCode;
  const textMap = {
    'registrasi': 'Registrasi',
    'proses verifikasi': 'Proses Verifikasi',
    'dikembalikan': 'Dikembalikan',
    'proses penerbitan str': 'Penerbitan STR',
    'aktif': 'Aktif',
    'kadaluarsa': 'Kadaluarsa',
    'dibekukan': 'Dibekukan',
    'dicabut': 'Dicabut',
    'menunggu pembayaran': 'Menunggu Pembayaran',
    'terverifikasi': 'Terverifikasi',
  };
  final byText = textMap[rawStatus.replaceAll('_', ' ').trim()];
  if (byText != null) return byText;
  return null;
}

String _fullAddress(Map<String, dynamic> data) {
  final parts = [
    _text(_deepPick(data,
        const ['alamat_latik', 'alamat', 'address', 'alamat_perusahaan'])),
    _text(_deepPick(data, const [
      'nama_kabupaten',
      'kota',
      'city_name',
      'kabupaten_alamat_latik',
      'kabupaten',
      'city'
    ])),
    _text(_deepPick(data, const [
      'nama_provinsi',
      'provinsi',
      'province_name',
      'provinsi_alamat_latik',
      'province'
    ])),
  ].where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  final zip = _text(_deepPick(data, const ['kode_pos', 'postal_code']));
  final joined = parts.join(', ');
  return zip.isEmpty ? joined : '$joined $zip';
}

String _periodText(DateTime? start, DateTime? end) {
  if (start != null && end != null) {
    return '${AppFormatters.formatShortDate(start)} – '
        '${AppFormatters.formatShortDate(end)}';
  }
  if (end != null) return 's.d. ${AppFormatters.formatShortDate(end)}';
  if (start != null) return 'sejak ${AppFormatters.formatShortDate(start)}';
  return '';
}

int? _intValue(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final parsed = parseInt(data[key]);
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? _date(String value) => parseFlexibleDate(value);

String _text(String value) => value.trim();

bool _hasProfileData(Map<String, dynamic> data) {
  const keys = [
    'nama_latik',
    'nama_latik_perusahaan',
    'name',
    'nama',
    'email',
    'email_latik',
    'email_institusi',
    'alamat_latik',
    'alamat',
    'address',
    'no_nib_latik',
    'nib',
    'nomor_nib',
    'no_nib',
  ];
  return _deepPick(data, keys).isNotEmpty;
}

String _deepPick(Map<String, dynamic> data, List<String> keys) =>
    pickString(data, keys, deep: true, fallback: '')!;

void _launchUrl(String url, {bool mailto = false}) {
  var target = url.trim();
  if (mailto && !target.startsWith('mailto:')) target = 'mailto:$target';
  if (!mailto && !target.contains('://')) target = 'https://$target';
  final uri = Uri.tryParse(target);
  if (uri == null) return;
  final scheme = uri.scheme;
  if (scheme != 'http' && scheme != 'https' && scheme != 'mailto') return;
  launchUrl(uri,
      mode: mailto
          ? LaunchMode.externalApplication
          : LaunchMode.inAppBrowserView);
}

String? latikScopeName(String raw) {
  final t = raw.trim().toLowerCase().replaceAll('_', ' ');
  if (t.isEmpty || t == 'null') return null;
  if (t.contains('aplikasi')) return 'Aplikasi';
  if (t.contains('infrastruktur')) return 'Infrastruktur';
  if (t.contains('keamanan')) return 'Keamanan Informasi';
  if (t.contains('organisasi') || t.contains('tata kelola')) {
    return 'Organisasi';
  }
  return null;
}

List<String> latikScopeLabels(Object? raw) {
  final result = <String>[];

  void add(String? label) {
    if (label != null && !result.contains(label)) result.add(label);
  }

  if (raw is Map) {
    raw.forEach((key, value) {
      if (value == true || value == 1 || value == '1') {
        add(latikScopeName(key.toString()));
      } else if (value is String &&
          const {'true', '1', 'aktif', 'active', 'ya', 'yes'}
              .contains(value.trim().toLowerCase())) {
        add(latikScopeName(key.toString()));
      }
    });
    return result;
  }
  if (raw is List) {
    for (final item in raw) {
      if (item == null) continue;
      add(latikScopeName(item.toString()));
    }
    return result;
  }
  if (raw is String && raw.trim().isNotEmpty && raw != 'null') {
    for (final part in raw.split(',')) {
      add(latikScopeName(part));
    }
  }
  return result;
}
