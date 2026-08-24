import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/notifikasi_provider.dart';

class NotifikasiScreen extends ConsumerStatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  ConsumerState<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends ConsumerState<NotifikasiScreen> {
  String filter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(notifikasiProvider);
    const filters = ['Semua', 'Belum Dibaca', 'Info'];

    return Stack(
      children: [
        const _BlueHeaderBand(height: 140),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifikasi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Kelola notifikasi Anda',
                            style: TextStyle(
                              color: Color(0xDDEAF2FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.go(AppRoutes.dashboard),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  itemCount: filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final item = filters[index];
                    final selected = filter == item;
                    return ChoiceChip(
                      label: Text(item),
                      selected: selected,
                      onSelected: (_) => setState(() => filter = item),
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF243552),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFFE4ECF7),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: asyncData.when(
                  data: (items) {
                    final filtered = items
                        .where((item) =>
                            filter == 'Semua' ||
                            (filter == 'Belum Dibaca'
                                ? !item.isRead
                                : item.kategori == filter))
                        .toList();

                    if (filtered.isEmpty) {
                      return const Center(
                          child: Text(
                              'Belum ada notifikasi untuk filter ini.'));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 120),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final item = filtered[index];
                        final color = item.kategori == 'Tindakan Diperlukan'
                            ? AppColors.accent
                            : (item.kategori == 'Info'
                                ? AppColors.primary
                                : AppColors.success);
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border:
                                Border.all(color: const Color(0xFFE4ECF7)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0B2D5C)
                                    .withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(_iconFor(item.kategori),
                                    color: color, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.judul,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF1C2638),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _timeAgo(item.waktu),
                                          style: const TextStyle(
                                            color: Color(0xFF8A96AA),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      item.isi,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF5B6880),
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                    ),
                                    if (item.actionUrl != null &&
                                        item.actionUrl!
                                            .trim()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton.icon(
                                          onPressed: () =>
                                              _openAction(item.actionUrl!),
                                          icon: const Icon(
                                              Icons.open_in_new,
                                              size: 16),
                                          label: const Text('Buka'),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            foregroundColor:
                                                AppColors.primary,
                                            textStyle: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) =>
                      const Center(child: Text('Gagal memuat notifikasi')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _iconFor(String kategori) {
    if (kategori == 'Tindakan Diperlukan') {
      return Icons.assignment_late_outlined;
    }
    if (kategori == 'Info') {
      return Icons.info_outline_rounded;
    }
    return Icons.description_outlined;
  }

  String _timeAgo(DateTime waktu) {
    final d = DateTime.now().difference(waktu);
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    if (d.inDays == 1) return 'Kemarin';
    return '${d.inDays} hari lalu';
  }

  Future<void> _openAction(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _BlueHeaderBand extends StatelessWidget {
  const _BlueHeaderBand({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height + MediaQuery.paddingOf(context).top,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0057B8), Color(0xFF003D7A)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
    );
  }
}
