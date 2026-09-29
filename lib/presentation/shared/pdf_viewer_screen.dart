import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/constants/api_endpoints.dart';
import '../../providers/auth_provider.dart';

final _externalDioProvider = Provider<Dio>((ref) => Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/pdf'},
      ),
    ));

class PdfViewerScreen extends ConsumerStatefulWidget {
  const PdfViewerScreen({super.key, this.invoiceRef, this.url})
      : assert(
          invoiceRef != null || url != null,
          'Either invoiceRef or url must be provided',
        );

  final String? invoiceRef;
  final String? url;

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  static const MethodChannel _downloadsChannel =
      MethodChannel('silatik_mobile/downloads');

  late Future<Uint8List> _bytesFuture;
  bool _saving = false;

  bool get _isNetworkUrl => widget.url != null;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _download();
  }

  Future<Uint8List> _download() async {
    if (_isNetworkUrl) {
      final externalDio = ref.read(_externalDioProvider);
      final response = await externalDio.get<List<int>>(
        widget.url!,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/pdf'},
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw StateError('PDF kosong');
      }
      return Uint8List.fromList(bytes);
    }
    final dio = ref.read(dioProvider);
    final response = await dio.get<List<int>>(
      '${ApiEndpoints.latikInvoice}/${widget.invoiceRef}',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': 'application/pdf'},
      ),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('PDF kosong');
    }
    return Uint8List.fromList(bytes);
  }

  void _retry() {
    setState(() => _bytesFuture = _download());
  }

  Future<void> _saveToDisk() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final name = _fileName();
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _enqueueAndroidDownload(name);
        _snack('PDF sedang diunduh, cek notifikasi');
        return;
      }
      final bytes = await _bytesFuture;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // The share sheet is the feedback here; no snackbar on success.
        await _shareIos(bytes, name);
      } else {
        final file = await _writeToFirstWritableDir(bytes, name);
        _snack('PDF tersimpan di ${file.path}');
      }
    } catch (e) {
      // Keep the real error in the log so a failed save is locatable; the
      // user only sees the generic snackbar.
      debugPrint('PdfViewerScreen: gagal menyimpan PDF: $e');
      _snack('Gagal mengunduh PDF');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _enqueueAndroidDownload(String name) async {
    await _downloadsChannel.invokeMethod<void>('enqueueDownload', {
      'url': _absoluteDownloadUrl(),
      'fileName': name,
      'headers': await _downloadHeaders(),
    });
  }

  /// Absolute URL for the file, resolving the invoice API path against the
  /// client's base URL (which always ends in "/").
  String _absoluteDownloadUrl() {
    if (_isNetworkUrl) return widget.url!;
    final base = ref.read(dioProvider).options.baseUrl;
    return '$base${ApiEndpoints.latikInvoice}/${widget.invoiceRef}';
  }

  /// Headers the app's API client would send. External URLs are pre-signed and
  /// need no auth; the invoice endpoint requires the bearer token.
  Future<Map<String, String>> _downloadHeaders() async {
    if (_isNetworkUrl) return const {};
    final token = await ref.read(storageProvider).getToken();
    if (token == null || token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }

  Future<void> _shareIos(Uint8List bytes, String name) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, name));
    await file.writeAsBytes(bytes, flush: true);
    try {
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } finally {
      try {
        await file.delete();
      } on FileSystemException {
        // The share target may still hold the file; the OS reclaims temp.
      }
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<File> _writeToFirstWritableDir(Uint8List bytes, String name) async {
    final candidates = [
      await getDownloadsDirectory(),
      await getApplicationDocumentsDirectory(),
    ].whereType<Directory>().toList();
    Object? lastError;
    for (final dir in candidates) {
      try {
        await dir.create(recursive: true);
        final file = File(p.join(dir.path, name));
        await file.writeAsBytes(bytes, flush: true);
        return file;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? StateError('Tidak ada direktori yang dapat ditulisi');
  }

  static final _leadingUuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[_-]?',
    caseSensitive: false,
  );
  static final _leadingNumericId = RegExp(r'^\d{8,}[_-]?');

  static final _controlChars = RegExp(r'[\x00-\x1F\x7F]');
  static final _invalidFileChars = RegExp(r'[\\/:*?"<>|]');
  static final _whitespaceRuns = RegExp(r'\s+');

  String _fileName() {
    final url = widget.url;
    if (url != null) {
      final cleaned = _sanitizeFileName(Uri.tryParse(url)?.pathSegments.last ?? '');
      if (cleaned.isNotEmpty) {
        return cleaned.toLowerCase().endsWith('.pdf') ? cleaned : '$cleaned.pdf';
      }
    }
    final ref = widget.invoiceRef;
    if (ref != null && ref.trim().isNotEmpty) {
      return 'invoice-${ref.trim()}.pdf';
    }
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'dokumen-${now.year}-${two(now.month)}-${two(now.day)}'
        '-${two(now.hour)}-${two(now.minute)}-${two(now.second)}.pdf';
  }

  static String _sanitizeFileName(String raw) {
    return raw
        .replaceAll(_controlChars, ' ')
        .replaceAll(_invalidFileChars, '_')
        .replaceFirst(_leadingUuid, '')
        .replaceFirst(_leadingNumericId, '')
        .replaceAll(_whitespaceRuns, ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNetworkUrl ? 'Dokumen' : 'Invoice'),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            tooltip: 'Unduh PDF',
            onPressed: _saving ? null : _saveToDisk,
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: _bytesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Gagal memuat PDF'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }
          return SfPdfViewer.memory(snapshot.data!);
        },
      ),
    );
  }
}
