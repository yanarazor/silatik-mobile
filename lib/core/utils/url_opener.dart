import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_routes.dart';

bool isPdfUrl(String url) =>
    url.trim().toLowerCase().split(RegExp(r'[?#]')).first.endsWith('.pdf');

Future<void> openFileUrl(
  BuildContext context,
  String url, {
  String emptyMessage = 'Berkas belum tersedia',
  String invalidMessage = 'URL dokumen tidak valid',
  String failureMessage = 'Gagal membuka dokumen',
}) async {
  final clean = url.trim();
  if (clean.isEmpty) {
    _snack(context, emptyMessage);
    return;
  }
  final uri = Uri.tryParse(clean);
  if (uri == null || !uri.hasScheme) {
    _snack(context, invalidMessage);
    return;
  }
  if (isPdfUrl(clean)) {
    context.push('${AppRoutes.pdfViewer}?url=${Uri.encodeComponent(clean)}');
    return;
  }
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.inAppWebView);
    if (!ok) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (_) {
    if (context.mounted) _snack(context, failureMessage);
  }
}

void _snack(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
