import 'dart:io';

import 'package:dio/dio.dart';

/// Bare client for document downloads. It deliberately does NOT use the app
/// [Dio] from `dioProvider`: that client attaches the auth token and, on 401,
/// triggers a global logout. Stored document URLs are external and may be
/// stale or reject the token, so a 401 here must surface as a failed copy
/// instead of logging the user out mid-wizard.
final Dio _downloadDio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ),
);

/// Downloads a remote document to a local temp file so it can be re-uploaded
/// as a real multipart `File` (the save endpoints have no URL pass-through).
///
/// The destination lives in the OS temp dir with a millisecond timestamp
/// prefix to avoid collisions; the OS owns cleanup, so callers never delete it.
Future<File> downloadToFile(String url) async {
  final target = File(
    '${Directory.systemTemp.path}/reuse_${DateTime.now().millisecondsSinceEpoch}_${_basename(url)}',
  );
  await _downloadDio.download(url, target.path);
  // A 2xx with an empty body would upload a broken file later, so fail loud.
  if (!target.existsSync() || target.lengthSync() == 0) {
    throw const FileSystemException('Berkas hasil unduhan kosong');
  }
  return target;
}

/// Derives a filename from the URL's last path segment, stripped of query and
/// fragment and URI-decoded. Falls back to `dokumen.pdf` when the URL carries
/// no usable segment.
String _basename(String url) {
  final path = Uri.tryParse(url.trim())?.path ?? url.trim();
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  final segment = segments.isEmpty ? '' : segments.last;
  final decoded = Uri.decodeComponent(segment).replaceAll(RegExp(r'[/\\]'), '_');
  return decoded.isEmpty ? 'dokumen.pdf' : decoded;
}
