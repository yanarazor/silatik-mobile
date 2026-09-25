import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/profil_dokumen.dart';
import '../../../data/models/registrasi_model.dart';
import '../../shared/dokumen_upload_card.dart';
import '../../shared/widgets/nomor_tanggal_fields.dart';

/// Formats a picked date as `dd-MM-yyyy` for the dokumen batch payload.
String formatDocDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd-$mm-${d.year}';
}

/// Derives a display file name from a server document URL.
String fileNameFromUrl(String url) {
  final clean = url.split('?').first;
  final seg = clean.split('/').where((s) => s.isNotEmpty).toList();
  return seg.isEmpty ? 'dokumen' : Uri.decodeComponent(seg.last);
}

/// State edit per dokumen (sama seperti dokumen_berkas_edit_screen). `file`
/// bisa berkas lokal baru atau berkas server lama (path berupa URL).
/// `newlyPicked` menandai file lokal yang harus ikut dikirim saat submit.
class DocEdit {
  FileItem? file;
  bool newlyPicked;
  final TextEditingController nomor;
  DateTime? tanggal;

  DocEdit({this.file, String nomor = '', this.tanggal})
      : newlyPicked = false,
        nomor = TextEditingController(text: nomor);
}

/// Langkah 2 — Dokumen Pendukung editable. Mengikuti dokumen_berkas_edit_screen.
class DokumenStep extends StatelessWidget {
  const DokumenStep({
    super.key,
    required this.docsAsync,
    required this.ensureInit,
    required this.edits,
    required this.onPick,
    required this.onPreview,
    required this.onPickDate,
    required this.onRetry,
    required this.onBack,
    required this.onNext,
  });

  final AsyncValue<List<ProfilDokumen>> docsAsync;
  final void Function(List<ProfilDokumen>) ensureInit;
  final Map<int, DocEdit> edits;
  final void Function(int) onPick;
  final void Function(FileItem) onPreview;
  final void Function(int, DateTime?) onPickDate;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return docsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gagal memuat dokumen'),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
      data: (loaded) {
        // Init edit-state from fresh data, then render from `loaded` directly.
        // Rendering from the parent's `docs` field caused a blank first paint:
        // on first build `docs` was still empty because ensureInit populates it
        // without a rebuild — only a later rebuild (Kembali→Selanjutnya) showed
        // it. Using `loaded` renders correctly on the first paint.
        ensureInit(loaded);
        final shown = loaded.where((d) => d.id != null).toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: shown.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppTheme.spacing16),
                  itemBuilder: (_, i) => _docGroup(context, shown[i]),
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacing12),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium)),
                      ),
                      child: const Text('Kembali'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacing12),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium)),
                      ),
                      child: const Text('Selanjutnya'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _docGroup(BuildContext context, ProfilDokumen d) {
    final e = edits[d.id]!;
    final hasExtra = d.nomorRequired || d.tanggalRequired;
    return DokumenUploadCard(
      title: d.nama.isEmpty ? 'Dokumen' : d.nama,
      requiredDoc: d.fileRequired,
      file: e.file,
      onPick: () => onPick(d.id!),
      onPreview: () {
        final f = e.file;
        if (f != null) onPreview(f);
      },
      extraFields: hasExtra
          ? NomorTanggalFields(
              showNomor: d.nomorRequired,
              showTanggal: d.tanggalRequired,
              nomor: e.nomor.text,
              tanggal: e.tanggal,
              onNomor: (v) => e.nomor.text = v,
              onTanggal: () => onPickDate(d.id!, e.tanggal),
            )
          : null,
    );
  }
}