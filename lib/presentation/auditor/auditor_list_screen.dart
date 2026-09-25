import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/auditor_model.dart';
import '../../providers/auditor_provider.dart';
import '../shared/blue_header_band.dart';
import '../shared/error_retry.dart';
import '../shared/header_filter_pills.dart';
import '../shared/header_title.dart';
import 'auditor_detail_screen.dart';
import 'form/auditor_form_screen.dart';
import 'widgets/auditor_card.dart';

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
          HeaderTitle(
            title: 'Kelola Auditor',
            subtitle: '${all.length} auditor terdaftar',
            trailing: FilledButton.icon(
              onPressed: () => openAuditorForm(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryLight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
            ),
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
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w500),
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
            borderSide: BorderSide(
                color: AppColors.primaryLight.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPills(Map<_Filter, int> counts) {
    const labels = {
      _Filter.semua: 'Semua',
      _Filter.aktif: 'Aktif',
      _Filter.verifikasi: 'Belum Verifikasi',
      _Filter.tidakAktif: 'Tidak Aktif',
    };

    return HeaderFilterPills<_Filter>(
      selected: _filter,
      onSelected: (value) => setState(() => _filter = value),
      options: [
        for (final item in _Filter.values)
          HeaderFilterOption(
            value: item,
            label: labels[item]!,
            count: counts[item] ?? 0,
          ),
      ],
    );
  }

  Widget _buildBody(AsyncValue<List<AuditorModel>> async) {
    if (async.isLoading && !async.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (async.hasError && !async.hasValue) {
      return ErrorRetry(
        message: 'Gagal memuat auditor',
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
                          onPressed: () => openAuditorForm(context),
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
                child: AuditorCard(
                  auditor: filtered[i],
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => AuditorDetailScreen(auditor: filtered[i]),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}