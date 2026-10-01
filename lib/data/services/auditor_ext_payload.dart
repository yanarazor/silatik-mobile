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

class AuditorRevisiDokumenUpload {
  final File file;
  final String fileName;
  final String nomor;
  final DateTime? tanggal;

  const AuditorRevisiDokumenUpload({
    required this.file,
    required this.fileName,
    required this.nomor,
    this.tanggal,
  });
}

class AuditorRevisiBatch {
  final String auditorRef;
  final String? refExt;
  final List<AuditorRevisiDokumenUpload> dokumens;

  const AuditorRevisiBatch({
    required this.auditorRef,
    this.refExt,
    required this.dokumens,
  });
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

Future<FormData> buildAuditorRevisiSaveDokumenFormData({
  required String latikRef,
  required List<AuditorRevisiBatch> batches,
}) async {
  final map = <String, dynamic>{'ref_latik': latikRef};
  for (var i = 0; i < batches.length; i++) {
    final batch = batches[i];
    map['auditors[$i][ref_auditor]'] = batch.auditorRef;
    if (batch.refExt != null) {
      map['auditors[$i][ref_ext]'] = batch.refExt;
    }
    for (var j = 0; j < batch.dokumens.length; j++) {
      final doc = batch.dokumens[j];
      final base = 'auditors[$i][dokumens][$j]';
      map['$base[nomor]'] = doc.nomor;
      if (doc.tanggal != null) {
        map['$base[tanggal]'] = _auditorExtUploadDate.format(doc.tanggal!);
      }
      map['$base[fileDokumen]'] = await MultipartFile.fromFile(
        doc.file.path,
        filename: doc.fileName,
      );
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

Future<FormData> buildAuditorAddCreateInvoiceFormData({
  required List<AuditorAddInvoiceItem> auditors,
}) async {
  final auditorJson = jsonEncode({
    'auditor': [
      for (final a in auditors)
        {
          'ref': a.ref,
          'nama': a.nama,
          'status': a.status == 1 ? '1' : '0',
          'is_new': '3',
        },
    ],
  });

  return FormData.fromMap({
    'is_new': '3',
    'auditor': auditorJson,
  });
}

class AuditorAddInvoiceItem {
  final String ref;
  final String nama;
  final int? status;

  const AuditorAddInvoiceItem({
    required this.ref,
    required this.nama,
    this.status,
  });
}

class LatikRegAuditorItem {
  final String ref;
  final String nama;
  final int? status;

  const LatikRegAuditorItem({
    required this.ref,
    required this.nama,
    this.status,
  });

  bool get isTetap => status == 1;
}

FormData buildLatikRegistrationInvoiceFormData({
  required List<LatikRegAuditorItem> auditors,
}) {
  final auditorJson = jsonEncode({
    'auditor': [
      for (final a in auditors)
        {
          'ref': a.ref,
          'nama': a.nama,
          'status': a.isTetap ? '1' : '0',
          'is_new': '1',
        },
    ],
  });

  return FormData.fromMap({
    'is_new': '1',
    'auditor': auditorJson,
  });
}

int latikRegistrationTotal(List<LatikRegAuditorItem> auditors) {
  const base = 5000000;
  const perAuditor = 1000000;
  final firstTetapIdx = auditors.indexWhere((a) => a.isTetap);
  final freeCount = firstTetapIdx == -1 ? 0 : 1;
  final nonFree = auditors.length - freeCount;
  return base + nonFree * perAuditor;
}
