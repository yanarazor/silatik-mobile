import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class AuditorExtDokumenUpload {
  final int id;
  final File? file;
  final String? fileName;
  final String nomor;

  final DateTime? tanggal;

  const AuditorExtDokumenUpload({
    required this.id,
    this.file,
    this.fileName,
    this.nomor = '',
    this.tanggal,
  });
}

class AuditorExtBatch {
  final String auditorRef;
  final List<AuditorExtDokumenUpload> dokumens;

  const AuditorExtBatch({required this.auditorRef, required this.dokumens});
}

class AuditorExtInvoiceItem {
  final String nama;
  final String ref;

  const AuditorExtInvoiceItem({required this.nama, required this.ref});
}

final DateFormat _auditorExtUploadDate = DateFormat('d-MM-y');

Future<FormData> buildAuditorExtSaveDokumenFormData({
  required String latikRef,
  required String latikExt,
  required List<AuditorExtBatch> batches,
}) async {
  final map = <String, dynamic>{
    'latik_ref': latikRef,
    'latik_ext': latikExt,
  };

  for (var i = 0; i < batches.length; i++) {
    final b = batches[i];
    map['auditors[$i][auditor_ref]'] = b.auditorRef;
    for (var j = 0; j < b.dokumens.length; j++) {
      final d = b.dokumens[j];
      final base = 'auditors[$i][dokumens][$j]';
      map['$base[nomor]'] = d.nomor;
      if (d.tanggal != null) {
        map['$base[tanggal]'] = _auditorExtUploadDate.format(d.tanggal!);
      }
      final file = d.file;
      if (file != null) {
        map['$base[fileDokumen]'] =
            await MultipartFile.fromFile(file.path, filename: d.fileName);
      }
    }
  }

  return FormData.fromMap(map);
}

Future<FormData> buildAuditorExtCreateInvoiceFormData({
  required String latikRef,
  required String latikExt,
  required List<AuditorExtInvoiceItem> auditors,
}) async {
  final auditorJson = jsonEncode({
    'auditor': [
      for (final a in auditors)
        {
          'is_new': '2',
          'nama': a.nama,
          'ref': a.ref,
          'ref_auditor_ext': latikExt,
          'status': '1',
        },
    ],
  });

  return FormData.fromMap({
    'is_new': '2',
    'auditor': auditorJson,
    'latik_ext': latikExt,
    'latik_ref': latikRef,
  });
}
