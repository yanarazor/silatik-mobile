import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/constants/api_endpoints.dart';
import '../../providers/auth_provider.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  const PdfViewerScreen({super.key, required this.invoiceRef});

  final String invoiceRef;

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  late Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _download();
  }

  Future<Uint8List> _download() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
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
