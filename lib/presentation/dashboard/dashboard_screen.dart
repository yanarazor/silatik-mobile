import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../data/models/notifikasi_model.dart';
import '../../providers/notifikasi_provider.dart';
import '../../providers/profile_menu_provider.dart';
import '../shared/blue_header_band.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(unreadNotificationProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    final latikAsync = ref.watch(latikProfileProvider);
    final latik = latikAsync.valueOrNull ?? const <String, dynamic>{};
    final namaLatik = _value(
        latik,
        const [
          'nama_latik',
          'nama_latik_perusahaan',
          'nama',
          'name',
          'first_name'
        ],
        fallback: 'LATIK');

    return Stack(
      children: [
        const BlueHeaderBand(height: 164),
        SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(latikProfileProvider);
              ref.invalidate(unreadNotificationProvider);
              ref.invalidate(unreadNotificationCountProvider);
              await Future.wait([
                ref
                    .read(latikProfileProvider.future)
                    .catchError((_) => <String, dynamic>{}),
                ref
                    .read(unreadNotificationProvider.future)
                    .catchError((_) => <NotifikasiModel>[]),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            namaLatik,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xDDEAF2FF),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          context.go(AppRoutes.notifications),
                      icon: Badge(
                        isLabelVisible: (unreadCountAsync.valueOrNull ?? 0) >
                            0,
                        label: Text(
                          '${unreadCountAsync.valueOrNull ?? 0}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        child: const Icon(Icons.notifications_rounded,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                latikAsync.when(
                  data: (data) => _LatikSummaryCard(data: data),
                  loading: () => const _LoadingCard(),
                  error: (_, __) => _ErrorCard(
                    onRetry: () => ref.invalidate(latikProfileProvider),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Aksi Cepat',
                  style: TextStyle(
                    color: Color(0xFF0C2D5C),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.description_outlined,
                      label: 'Dokumen',
                      onTap: () => context.push(AppRoutes.registration),
                    ),
                    const SizedBox(width: 18),
                    _QuickAction(
                      icon: Icons.groups_2_outlined,
                      label: 'Auditor',
                      onTap: () => context.go(AppRoutes.auditors),
                    ),
                    const SizedBox(width: 18),
                    _QuickAction(
                      icon: Icons.autorenew_rounded,
                      label: 'Perpanjangan',
                      onTap: () => context.push(AppRoutes.registration),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'Notifikasi Terbaru',
                  style: TextStyle(
                    color: Color(0xFF0C2D5C),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                notifAsync.when(
                  data: (items) {
                    final latest = items.take(2).toList();
                    if (latest.isEmpty) {
                      return const Text('Belum ada notifikasi');
                    }
                    return Column(
                      children: latest.map((item) {
                        final isWarning =
                            item.kategori == 'Tindakan Diperlukan';
                        final actionUrl = item.actionUrl?.trim();
                        return InkWell(
                          onTap: actionUrl != null && actionUrl.isNotEmpty
                              ? () {
                                  final uri = Uri.tryParse(actionUrl);
                                  if (uri != null &&
                                      _invoiceRefFromUrl(uri) != null) {
                                    ref
                                        .read(notifikasiListProvider.notifier)
                                        .markAsRead(item.id);
                                  }
                                  _openAction(context, actionUrl);
                                }
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 11,
                                  height: 11,
                                  decoration: BoxDecoration(
                                    color: isWarning
                                        ? AppColors.accent
                                        : AppColors.primary,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.judul,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF1C2638),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (item.isi.trim().isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.isi,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF6B778C),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _timeAgo(item.waktu),
                                  style: const TextStyle(
                                    color: Color(0xFF8A96AA),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (actionUrl != null &&
                                    actionUrl.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.open_in_new,
                                      size: 14, color: AppColors.primary),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Gagal memuat notifikasi'),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.notifications),
                    child: const Text(
                      'Lihat semua notifikasi  >',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _timeAgo(DateTime waktu) {
    final d = DateTime.now().difference(waktu);
    if (d.inMinutes < 60) return '${d.inMinutes} mnt lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    return '${d.inDays} hari lalu';
  }

  static Future<void> _openAction(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final invoiceRef = _invoiceRefFromUrl(uri);
    if (invoiceRef != null) {
      context.push(
          '${AppRoutes.pdfViewer}?ref=${Uri.encodeQueryComponent(invoiceRef)}');
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String? _invoiceRefFromUrl(Uri uri) {
    final segments =
        uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
    for (var i = 0; i < segments.length; i++) {
      if ((segments[i] == 'invoice' || segments[i] == 'transaction') &&
          i + 1 < segments.length) {
        return segments[i + 1];
      }
    }
    return null;
  }

  static String _value(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '-',
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return fallback;
  }
}

class _LatikSummaryCard extends StatelessWidget {
  const _LatikSummaryCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final nomorStr = DashboardScreen._value(
        data, const ['nomor_str', 'no_str', 'str_number']);
    final nomorRegistrasi = DashboardScreen._value(
      data,
      const [
        'no_pendaftaran',
        'nomor_registrasi',
        'no_registrasi',
        'registration_number',
        'kode_registrasi',
        'kode_register',
        'kode',
        'no_register',
        'nomor_register',
        'registration_code'
      ],
    );
    final namaLatik = DashboardScreen._value(
      data,
      const [
        'nama_latik',
        'nama_latik_perusahaan',
        'nama',
        'name',
        'first_name'
      ],
    );
    final fallbackStatus = nomorStr == '-' ? 'Data LATIK' : 'STR Aktif';
    final status = DashboardScreen._value(
      data,
      const [
        'nama_status',
        'nama_status_str',
        'status_verifikasi',
        'status',
        'status_latik',
        'verification_status'
      ],
      fallback: fallbackStatus,
    );
    final statusText = status.toLowerCase();
    final isVerified = statusText.contains('terverifikasi') ||
        statusText.contains('sudah verifikasi') ||
        statusText.contains('aktif') ||
        statusText.contains('approved');
    final statusIcon =
        isVerified ? Icons.check_circle_rounded : Icons.hourglass_top_rounded;
    final statusColor = isVerified ? const Color(0xFF25B45B) : AppColors.accent;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _showLatikDetail(context, data),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFEAF2FF)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE4ECF7)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B2D5C).withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status Registrasi',
                style: TextStyle(
                  color: Color(0xFF5B6880),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Color(0xFF1C2638),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFA7B0C3)),
                ],
              ),
              const SizedBox(height: 18),
              _SummaryLine(label: 'No. Registrasi', value: nomorRegistrasi),
              const SizedBox(height: 6),
              _SummaryLine(label: 'No. STR', value: nomorStr),
              const SizedBox(height: 6),
              _SummaryLine(label: 'Nama LATIK', value: namaLatik),
            ],
          ),
        ),
      ),
    );
  }

  void _showLatikDetail(BuildContext context, Map<String, dynamic> data) {
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
                maxHeight: MediaQuery.sizeOf(context).height * 0.82),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  const Text(
                    'Detail Data LATIK',
                    style: TextStyle(
                      color: Color(0xFF0C2D5C),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoLine(
                    label: 'Nomor Registrasi',
                    value: DashboardScreen._value(data, const [
                      'no_pendaftaran',
                      'nomor_registrasi',
                      'no_registrasi',
                      'registration_number',
                      'kode_registrasi',
                      'kode_register',
                      'kode',
                      'no_register',
                      'nomor_register',
                      'registration_code'
                    ]),
                  ),
                  _InfoLine(
                      label: 'Status Verifikasi',
                      value: DashboardScreen._value(data, const [
                        'nama_status',
                        'nama_status_str',
                        'status_verifikasi',
                        'status',
                        'status_latik',
                        'verification_status'
                      ])),
                  _InfoLine(
                      label: 'Nomor STR',
                      value: DashboardScreen._value(
                          data, const ['nomor_str', 'no_str', 'str_number'])),
                  _InfoLine(
                      label: 'Nomor NIB',
                      value: DashboardScreen._value(data, const [
                        'nib',
                        'nomor_nib',
                        'no_nib',
                        'no_nib_latik'
                      ])),
                  _InfoLine(
                      label: 'Nomor NPWP',
                      value: DashboardScreen._value(data, const [
                        'npwp',
                        'nomor_npwp',
                        'no_npwp',
                        'npwp_latik'
                      ])),
                  _InfoLine(
                      label: 'Nama LATIK',
                      value: DashboardScreen._value(data, const [
                        'nama_latik',
                        'nama_latik_perusahaan',
                        'nama',
                        'name',
                        'first_name'
                      ])),
                  _InfoLine(
                      label: 'Email',
                      value: DashboardScreen._value(
                          data, const ['email', 'email_latik'])),
                  _InfoLine(
                      label: 'Alamat LATIK',
                      value: DashboardScreen._value(data, const [
                        'alamat_latik',
                        'alamat',
                        'address',
                        'alamat_perusahaan'
                      ])),
                  _InfoLine(
                      label: 'Provinsi',
                      value: DashboardScreen._value(data, const [
                        'nama_provinsi',
                        'province_name',
                        'provinsi_alamat_latik',
                        'province',
                        'provinsi'
                      ])),
                  _InfoLine(
                      label: 'Kabupaten/Kota',
                      value: DashboardScreen._value(data, const [
                        'nama_kabupaten',
                        'city_name',
                        'kabupaten_alamat_latik',
                        'kota',
                        'city',
                        'kabupaten'
                      ])),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5B6880),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF243552),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4ECF7)),
      ),
      child: const CircularProgressIndicator(),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gagal memuat data LATIK',
            style: TextStyle(
              color: Color(0xFF1C2638),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tarik layar ke bawah atau tekan tombol untuk mencoba lagi.',
            style: TextStyle(color: Color(0xFF5B6880), fontSize: 12),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF243552),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
