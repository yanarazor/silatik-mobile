import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/url_opener.dart';

class DocReuseSource {
  final String nama;
  final String meta;

  final int? statusVerifikasi;

  final String nomor;
  final String tanggal;
  final String url;

  const DocReuseSource({
    required this.nama,
    this.meta = '',
    this.statusVerifikasi,
    this.nomor = '',
    this.tanggal = '',
    this.url = '',
  });

  bool get hasFile => url.trim().isNotEmpty;

  bool get verified => statusVerifikasi == 1;

  bool get tidakSah => statusVerifikasi == 2;
}

String docVerificationLabel(int? status) {
  return switch (status) {
    1 => 'Terverifikasi',
    2 => 'Tidak Sah',
    _ => 'Belum Verifikasi',
  };
}

Future<DocReuseSource?> showDocReusePicker(
  BuildContext context, {
  required String title,
  required String targetName,
  required bool targetRequired,
  required List<DocReuseSource> sources,
}) {
  return Navigator.of(context).push<DocReuseSource>(
    MaterialPageRoute(
      builder: (_) => DocReusePickerPage(
        title: title,
        targetName: targetName,
        targetRequired: targetRequired,
        sources: sources,
      ),
    ),
  );
}

class DocReusePickerPage extends StatefulWidget {
  const DocReusePickerPage({
    super.key,
    required this.title,
    required this.targetName,
    required this.targetRequired,
    required this.sources,
  });

  final String title;
  final String targetName;
  final bool targetRequired;
  final List<DocReuseSource> sources;

  @override
  State<DocReusePickerPage> createState() => _DocReusePickerPageState();
}

class _DocReusePickerPageState extends State<DocReusePickerPage> {
  final _searchController = TextEditingController();
  String _query = '';
  _ReuseFilter _filter = _ReuseFilter.semua;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DocReuseSource> get _visible {
    final q = _query.trim().toLowerCase();
    return widget.sources.where((s) {
      final matchesQuery = q.isEmpty ||
          s.nama.toLowerCase().contains(q) ||
          s.nomor.toLowerCase().contains(q) ||
          s.meta.toLowerCase().contains(q);
      final matchesFilter = switch (_filter) {
        _ReuseFilter.semua => true,
        _ReuseFilter.terverifikasi => s.verified,
        _ReuseFilter.belum => !s.verified && !s.tidakSah,
        _ReuseFilter.tidakSah => s.tidakSah,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  int get _verifiedCount => widget.sources.where((s) => s.verified).length;

  int get _tidakSahCount => widget.sources.where((s) => s.tidakSah).length;

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _targetBanner(),
            _searchField(),
            _filterChips(),
            Expanded(child: _list(visible)),
          ],
        ),
      ),
    );
  }

  Widget _targetBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spacing16, AppTheme.spacing16, AppTheme.spacing16, 0),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: const Icon(Icons.assignment_turned_in_outlined,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      const Text(
                        'TARGET PERSYARATAN',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      if (widget.targetRequired)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.warning,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Wajib Diisi',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.targetName.isEmpty ? 'Dokumen' : widget.targetName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Pilih salah satu berkas terverifikasi dari repositori '
                    'profil Anda untuk mempercepat validasi berkas.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.35,
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

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spacing16, AppTheme.spacing12, AppTheme.spacing16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari berkas dokumen tersimpan...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.cancel, size: 18),
                  tooltip: 'Bersihkan pencarian',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _filterChips() {
    final total = widget.sources.length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spacing16, AppTheme.spacing12, AppTheme.spacing16, 0),
      child: Row(
        children: [
          _ReuseChip(
            label: 'Semua',
            count: total,
            selected: _filter == _ReuseFilter.semua,
            onTap: () => setState(() => _filter = _ReuseFilter.semua),
          ),
          const SizedBox(width: AppTheme.spacing8),
          _ReuseChip(
            label: 'Terverifikasi',
            count: _verifiedCount,
            dotColor: AppColors.success,
            selected: _filter == _ReuseFilter.terverifikasi,
            onTap: () => setState(() => _filter = _ReuseFilter.terverifikasi),
          ),
          const SizedBox(width: AppTheme.spacing8),
          _ReuseChip(
            label: 'Belum Verifikasi',
            count: total - _verifiedCount - _tidakSahCount,
            dotColor: AppColors.warning,
            selected: _filter == _ReuseFilter.belum,
            onTap: () => setState(() => _filter = _ReuseFilter.belum),
          ),
          if (_tidakSahCount > 0) ...[
            const SizedBox(width: AppTheme.spacing8),
            _ReuseChip(
              label: 'Tidak Sah',
              count: _tidakSahCount,
              dotColor: AppColors.error,
              selected: _filter == _ReuseFilter.tidakSah,
              onTap: () => setState(() => _filter = _ReuseFilter.tidakSah),
            ),
          ],
        ],
      ),
    );
  }

  Widget _list(List<DocReuseSource> visible) {
    if (widget.sources.isEmpty) {
      return const _ReuseEmpty('Belum ada dokumen tersimpan.');
    }
    if (visible.isEmpty) {
      return const _ReuseEmpty('Tidak ada dokumen pada kategori ini');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacing12),
      itemBuilder: (context, i) => _ReuseCard(
        source: visible[i],
        onUse: () => Navigator.of(context).pop(visible[i]),
      ),
    );
  }
}

enum _ReuseFilter { semua, terverifikasi, belum, tidakSah }

class _ReuseChip extends StatelessWidget {
  const _ReuseChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: fg,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReuseCard extends StatelessWidget {
  const _ReuseCard({required this.source, required this.onUse});

  final DocReuseSource source;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf,
                          color: AppColors.error, size: 22),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusPill(
                        statusVerifikasi: source.statusVerifikasi,
                        hasFile: source.hasFile,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        source.nama.isEmpty ? 'Dokumen' : source.nama,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      if (source.meta.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Keterangan: ${source.meta}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing8, vertical: AppTheme.spacing4),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: source.hasFile
                          ? () => openFileUrl(context, source.url)
                          : null,
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Lihat Dokumen',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing8),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: source.hasFile ? onUse : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing16, vertical: 10),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: const Text('Gunakan'),
                    ),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.statusVerifikasi, required this.hasFile});

  final int? statusVerifikasi;
  final bool hasFile;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    if (!hasFile) {
      color = AppColors.textSecondary;
      icon = Icons.upload_file_outlined;
    } else if (statusVerifikasi == 1) {
      color = AppColors.success;
      icon = Icons.verified;
    } else if (statusVerifikasi == 2) {
      color = AppColors.error;
      icon = Icons.cancel_outlined;
    } else {
      color = AppColors.warning;
      icon = Icons.schedule;
    }
    final label =
        hasFile ? docVerificationLabel(statusVerifikasi) : 'Belum ada berkas';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReuseEmpty extends StatelessWidget {
  const _ReuseEmpty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_off_outlined,
                size: 44, color: Color(0xFFB4BDCC)),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
