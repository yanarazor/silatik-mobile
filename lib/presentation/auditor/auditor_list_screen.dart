import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/auditor_model.dart';
import '../../providers/auditor_provider.dart';
import '../registration/steps/step4_auditor.dart';
import '../shared/blue_header_band.dart';
import 'auditor_detail_screen.dart';

enum _Filter { semua, aktif, verifikasi, tidakAktif }

class AuditorListScreen extends ConsumerStatefulWidget {
  const AuditorListScreen({super.key});

  @override
  ConsumerState<AuditorListScreen> createState() => _AuditorListScreenState();
}

class _AuditorListScreenState extends ConsumerState<AuditorListScreen> {
  final _searchCtrl = TextEditingController();
  _Filter _filter = _Filter.semua;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AuditorModel> _apply(List<AuditorModel> list) {
    final q = _searchCtrl.text.trim().toLowerCase();
    return list.where((a) {
      if (q.isNotEmpty &&
          !a.nama.toLowerCase().contains(q) &&
          !a.nik.toLowerCase().contains(q)) {
        return false;
      }
      switch (_filter) {
        case _Filter.semua:
          return true;
        case _Filter.aktif:
          return a.statusAktif == 1;
        case _Filter.verifikasi:
          return a.statusVerifikasi != 1;
        case _Filter.tidakAktif:
          return a.statusAktif != 1;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(auditorListProvider);
    final all = async.valueOrNull ?? [];

    return Stack(
      children: [
        BlueHeaderBand(height: _headerHeight(all)),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(all),
              const SizedBox(height: 12),
              Expanded(child: _buildBody(async)),
            ],
          ),
        ),
      ],
    );
  }

  double _headerHeight(List<AuditorModel> all) {
    return 180;
  }

  Widget _buildHeader(List<AuditorModel> all) {
    final counts = {
      _Filter.semua: all.length,
      _Filter.aktif: all.where((a) => a.statusAktif == 1).length,
      _Filter.verifikasi: all.where((a) => a.statusVerifikasi != 1).length,
      _Filter.tidakAktif: all.where((a) => a.statusAktif != 1).length,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kelola Auditor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${all.length} auditor terdaftar',
                      style: const TextStyle(
                        color: Color(0xDDEAF2FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => showAuditorSheet(context, ref),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryLight,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSearchField(),
          const SizedBox(height: 12),
          _buildFilterPills(counts),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Cari auditor',
          hintStyle: const TextStyle(
              color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: Color(0xFF94A3B8)),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 16, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x0D000000)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: AppColors.primaryLight.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPills(Map<_Filter, int> counts) {
    final labels = {
      _Filter.semua: 'Semua',
      _Filter.aktif: 'Aktif',
      _Filter.verifikasi: 'Belum Verifikasi',
      _Filter.tidakAktif: 'Tidak Aktif',
    };

    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _Filter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final item = _Filter.values[i];
          final selected = _filter == item;
          final count = counts[item] ?? 0;
          return GestureDetector(
            onTap: () {
              if (_filter != item) setState(() => _filter = item);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: selected
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '${labels[item]} ($count)',
                style: TextStyle(
                  color: selected
                      ? AppColors.primaryLight
                      : Colors.white.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(AsyncValue<List<AuditorModel>> async) {
    if (async.isLoading && !async.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (async.hasError && !async.hasValue) {
      return _ErrorRetry(
        onRetry: () => ref.invalidate(auditorListProvider),
      );
    }
    final all = async.valueOrNull ?? [];
    final filtered = _apply(all);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(auditorListProvider);
        await ref.read(auditorListProvider.future);
      },
      child: filtered.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(all.isEmpty
                          ? Icons.people_outline_rounded
                          : Icons.filter_list_off_rounded),
                      const SizedBox(height: 16),
                      Text(
                        all.isEmpty
                            ? 'Belum ada auditor'
                            : 'Tidak ada auditor sesuai filter',
                        style: const TextStyle(
                          color: Color(0xFF1C2638),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (all.isEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => showAuditorSheet(context, ref),
                          child: const Text('Tambah Auditor'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              itemCount: filtered.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _AuditorCard(
                  auditor: filtered[i],
                  onTap: () =>
                      Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          AuditorDetailScreen(auditor: filtered[i]),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _AuditorCard extends StatelessWidget {
  const _AuditorCard({required this.auditor, required this.onTap});

  final AuditorModel auditor;
  final VoidCallback onTap;

  static const _avatarGradients = [
    [Color(0xFF004A8F), Color(0xFF0074D9)],
    [Color(0xFFB5651D), Color(0xFFD4943A)],
    [Color(0xFF4A5568), Color(0xFF718096)],
    [Color(0xFF004A8F), Color(0xFF0D9488)],
  ];

  @override
  Widget build(BuildContext context) {
    final initials = auditor.nama
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();
    final status = auditor.statusVerifikasi ?? 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF002E5D).withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, -1),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildAvatar(initials),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auditor.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NIK: ${AppFormatters.maskNik(auditor.nik)}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(verificationStatus: status),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            Row(
              children: [
                _RoleChip(auditor: auditor),
                const Spacer(),
                GestureDetector(
                  onTap: onTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Detail',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.primaryLight,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String initials) {
    final url = auditor.fotoUrl.trim();
    final colorIdx =
        auditor.nama.hashCode.abs() % _avatarGradients.length;
    final gradient = _avatarGradients[colorIdx];

    final avatar = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: url.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsText(initials),
              ),
            )
          : _initialsText(initials),
    );

    if (auditor.statusAktif == 1) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.check_rounded,
                  size: 10, color: Colors.white),
            ),
          ),
        ],
      );
    }
    return avatar;
  }

  Widget _initialsText(String initials) => Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 1,
        ),
      );

}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.verificationStatus});
  final int verificationStatus;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg, dotColor) = switch (verificationStatus) {
      1 => (
          'Valid',
          const Color(0xFFECFDF5),
          const Color(0xFF047857),
          const Color(0xFF10B981),
        ),
      2 => (
          'Invalid',
          const Color(0xFFF1F5F9),
          const Color(0xFF475569),
          const Color(0xFF94A3B8),
        ),
      _ => (
          'Belum Verifikasi',
          const Color(0xFFFEF2F2),
          const Color(0xFFB91C1C),
          const Color(0xFFEF4444),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.auditor});
  final AuditorModel auditor;

  @override
  Widget build(BuildContext context) {
    final isTetap = auditor.statusLabel.toLowerCase().contains('tetap');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isTetap
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isTetap
              ? const Color(0xFFBFDBFE)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        auditor.statusLabel,
        style: TextStyle(
          color: isTetap
              ? const Color(0xFF1D4ED8)
              : const Color(0xFF475569),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Gagal memuat auditor',
            style: TextStyle(
              color: Color(0xFF1C2638),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}
