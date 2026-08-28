import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_routes.dart';
import '../../providers/dokumen_provider.dart';
import '../shared/blue_header_band.dart';

class DokumenScreen extends ConsumerWidget {
  const DokumenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dokumenAsync = ref.watch(dokumenListProvider);
    final allDokumen = dokumenAsync.valueOrNull ?? const [];
    final query = ref.watch(_queryProvider);

    final filtered = allDokumen.where((d) {
      if (query.isEmpty) return true;
      return d.judul.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          const BlueHeaderBand(height: 164),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Unduh Dokumen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: TextField(
                    onChanged: (v) =>
                        ref.read(_queryProvider.notifier).state = v,
                    decoration: InputDecoration(
                      hintText: 'Cari Dokumen...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: Color(0xFFE4ECF7)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                Expanded(
                  child: dokumenAsync.when(
                    data: (data) {
                      if (data.isEmpty) {
                        return const _EmptyState();
                      }
                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text(
                            'Tidak ada dokumen yang cocok',
                            style: TextStyle(
                              color: Color(0xFF8A96AA),
                              fontSize: 13,
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Color(0xFFE4ECF7),
                          indent: 0,
                          endIndent: 0,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, index) => _DokumenTile(
                          document: filtered[index],
                          onTap: () => _openDocument(
                              context, ref, filtered[index]),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (err, _) => _ErrorState(
                      onRetry: () => ref.invalidate(dokumenListProvider),
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

  Future<void> _openDocument(
      BuildContext context, WidgetRef ref, dynamic doc) async {
    final url = doc.openUrl;
    if (url == null) return;

    if (doc.isPdf) {
      context.push(
          '${AppRoutes.pdfViewer}?url=${Uri.encodeQueryComponent(url)}');
    } else {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    }
  }
}

final _queryProvider = StateProvider<String>((ref) => '');

class _DokumenTile extends StatelessWidget {
  const _DokumenTile({required this.document, required this.onTap});

  final dynamic document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                document.judul,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF5B6880),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Buka'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Belum ada dokumen',
        style: TextStyle(
          color: Color(0xFF8A96AA),
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Gagal memuat dokumen',
            style: TextStyle(
              color: Color(0xFF1C2638),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
