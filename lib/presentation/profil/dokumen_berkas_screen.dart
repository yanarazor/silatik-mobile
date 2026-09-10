import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/profil_dokumen.dart';
import '../../providers/profile_menu_provider.dart';

enum _BerkasFilter { semua, terverifikasi, belum }

const _cardBorder = Color(0xFFE5EAF3);
const _cardDivider = Color(0xFFF0F2F7);
const _blueTint = Color(0xFFEBF3FA);
const _blueTintBorder = Color(0xFFD5E5F7);
const _green = Color(0xFF25B45B);

class DokumenBerkasScreen extends ConsumerWidget {
  const DokumenBerkasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(latikProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dokumen & Berkas'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Gagal memuat dokumen.',
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
        data: (profile) =>
            _DocsView(docs: ProfilDokumen.listFrom(profile)),
      ),
    );
  }
}

class _DocsView extends StatefulWidget {
  const _DocsView({required this.docs});

  final List<ProfilDokumen> docs;

  @override
  State<_DocsView> createState() => _DocsViewState();
}

class _DocsViewState extends State<_DocsView> {
  _BerkasFilter _filter = _BerkasFilter.semua;

  @override
  Widget build(BuildContext context) {
    final verified = widget.docs.where((d) => d.terverifikasi).length;
    final pending = widget.docs.length - verified;
    final visible = widget.docs.where((d) {
      switch (_filter) {
        case _BerkasFilter.semua:
          return true;
        case _BerkasFilter.terverifikasi:
          return d.terverifikasi;
        case _BerkasFilter.belum:
          return !d.terverifikasi;
      }
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _SummaryCard(
          total: widget.docs.length,
          verified: verified,
          pending: pending,
          filter: _filter,
          onFilter: (f) => setState(() => _filter = f),
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          _EmptyDocs(
            message: widget.docs.isEmpty
                ? 'Belum ada dokumen kelengkapan'
                : 'Tidak ada dokumen pada kategori ini',
          )
        else
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _DocCard(doc: visible[i]),
          ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.verified,
    required this.pending,
    required this.filter,
    required this.onFilter,
  });

  final int total;
  final int verified;
  final int pending;
  final _BerkasFilter filter;
  final ValueChanged<_BerkasFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _blueTint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _blueTintBorder),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total Dokumen Legalitas',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Kelengkapan berkas profil Lembaga SILATIK',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: _cardDivider),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'Semua ($total)',
                selected: filter == _BerkasFilter.semua,
                onTap: () => onFilter(_BerkasFilter.semua),
              ),
              _FilterChip(
                label: 'Terverifikasi ($verified)',
                dotColor: _green,
                selected: filter == _BerkasFilter.terverifikasi,
                onTap: () => onFilter(_BerkasFilter.terverifikasi),
              ),
              _FilterChip(
                label: 'Belum Diverifikasi ($pending)',
                dotColor: const Color(0xFF737781),
                selected: filter == _BerkasFilter.belum,
                onTap: () => onFilter(_BerkasFilter.belum),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFECEEF1),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF434750),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  const _DocCard({required this.doc});

  final ProfilDokumen doc;

  @override
  Widget build(BuildContext context) {
    final metaParts = [
      if (doc.nomor.isNotEmpty) 'No: ${doc.nomor}',
      if (doc.tanggal.isNotEmpty) _tanggalText(doc.tanggal),
    ];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      child: InkWell(
        onTap: () => _openDoc(context, doc),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            border: Border.all(color: _cardBorder.withValues(alpha: 0.6)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _blueTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _docIcon(doc.nama),
                      size: 22,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.nama.isEmpty ? 'Dokumen' : doc.nama,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                          ),
                        ),
                        if (metaParts.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            metaParts.join('  •  '),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _StatusPill(doc: doc),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Buka',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.open_in_new,
                          size: 13,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (doc.catatan.trim().isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Divider(height: 1, color: _cardDivider),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Keterangan: ${doc.catatan.trim()}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _tanggalText(String raw) {
    final date = DateTime.tryParse(raw.trim());
    if (date != null) return AppFormatters.formatShortDate(date);
    // ponytail: format dd-mm-yyyy / dd/mm/yyyy yang mungkin dikirim backend
    final m = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$')
        .firstMatch(raw.trim());
    if (m != null) {
      final parsed = DateTime(
          int.parse(m.group(3)!), int.parse(m.group(2)!), int.parse(m.group(1)!));
      return AppFormatters.formatShortDate(parsed);
    }
    return raw.trim();
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.doc});

  final ProfilDokumen doc;

  @override
  Widget build(BuildContext context) {
    final verified = doc.terverifikasi;
    final color = verified ? _green : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.check_circle : Icons.schedule,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            verified ? 'Terverifikasi' : 'Belum Diverifikasi',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDocs extends StatelessWidget {
  const _EmptyDocs({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          const Icon(
            Icons.folder_off_outlined,
            size: 44,
            color: Color(0xFFB4BDCC),
          ),
          const SizedBox(height: 12),
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
    );
  }
}

IconData _docIcon(String nama) {
  final t = nama.toLowerCase();
  if (t.contains('akta') || t.contains('badan hukum')) {
    return Icons.workspace_premium_outlined;
  }
  if (t.contains('nib') || t.contains('berusaha') || t.contains('bkpm')) {
    return Icons.badge_outlined;
  }
  if (t.contains('akreditasi') || t.contains('komite akreditasi')) {
    return Icons.assignment_turned_in_outlined;
  }
  if (t.contains('struktur')) return Icons.account_tree_outlined;
  if (t.contains('sop') || t.contains('pernyataan')) {
    return Icons.verified_user_outlined;
  }
  if (t.contains('npwp')) return Icons.description_outlined;
  return Icons.description_outlined;
}

Future<void> _openDoc(BuildContext context, ProfilDokumen doc) async {
  final url = doc.url.trim();
  if (url.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Berkas belum tersedia')),
    );
    return;
  }
  final uri = Uri.tryParse(url);
  if (uri == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL dokumen tidak valid')),
    );
    return;
  }
  if (url.toLowerCase().endsWith('.pdf')) {
    context.push('${AppRoutes.pdfViewer}?url=${Uri.encodeComponent(url)}');
    return;
  }
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.inAppWebView);
    if (!ok) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka dokumen')),
      );
    }
  }
}
