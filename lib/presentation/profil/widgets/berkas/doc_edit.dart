import 'package:flutter/material.dart';

import '../../../../data/models/registrasi_model.dart';

/// State edit per dokumen. `file` bisa berkas lokal baru (path lokal) atau
/// berkas server lama (path berupa URL). `newlyPicked` menandai file lokal
/// yang harus ikut dikirim saat submit.
class DocEdit {
  FileItem? file;
  bool newlyPicked;
  final TextEditingController nomor;
  DateTime? tanggal;

  DocEdit({this.file, String nomor = '', this.tanggal})
      : newlyPicked = false,
        nomor = TextEditingController(text: nomor);
}