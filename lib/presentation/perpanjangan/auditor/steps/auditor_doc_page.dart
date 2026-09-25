import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/url_opener.dart';
import '../../../../data/models/auditor_model.dart';
import '../../../../data/models/latik_ext_model.dart';
import '../../../../data/models/registrasi_model.dart';
import '../../../../providers/auditor_ext_provider.dart';
import '../../../auditor/form/auditor_profil_step.dart'
    show kAuditorFileMaxBytes;
import '../../../shared/dokumen_upload_card.dart';
import '../../../shared/widgets/nomor_tanggal_fields.dart';

/// Sub-halaman pengisian dokumen satu auditor. Murni state klien (provider);
/// "Selesai" hanya menutup halaman — tak ada penyimpanan server di sini.
class AuditorDocPage extends ConsumerWidget {
  const AuditorDocPage({
    super.key,
    required this.refExt,
    required this.auditorIndex,
    required this.auditor,
  });

  final String refExt;
  final int auditorIndex;
  final AuditorModel auditor;

  Future<void> _pick(BuildContext context, WidgetRef ref, int docId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;
    final file = result.files.single;
    if (file.size > kAuditorFileMaxBytes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ukuran file maksimal 10MB')),
        );
      }
      return;
    }
    ref.read(auditorExtProvider(refExt).notifier).setFile(
          docId,
          FileItem(path: file.path ?? '', name: file.name, size: file.size),
        );
  }

  Future<void> _preview(BuildContext context, FileItem doc) async {
    final path = doc.path.trim();
    if (path.toLowerCase().startsWith('http')) {
      await openFileUrl(context, path);
      return;
    }
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka berkas: ${result.message}')),
      );
    }
  }

  Future<void> _pickTanggal(
      BuildContext context, WidgetRef ref, int docId, DateTime? current) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      ref.read(auditorExtProvider(refExt).notifier).setTanggal(docId, picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Watch state so file/nomor/tanggal edits rebuild the cards.
    final state = ref.watch(auditorExtProvider(refExt));
    final notifier = ref.read(auditorExtProvider(refExt).notifier);
    final docs = notifier.docsForAuditor(auditorIndex);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFE),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          auditor.nama.isEmpty ? 'Dokumen Auditor' : auditor.nama,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
          child: ListView(
            children: [
              Text(
                'Unggah dokumen persyaratan (PDF, maks 10MB).',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacing16),
              for (final d in docs) ...[
                _docCard(context, ref, state, d),
                const SizedBox(height: AppTheme.spacing16),
              ],
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium)),
                ),
                child: const Text('Selesai'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _docCard(
    BuildContext context,
    WidgetRef ref,
    AuditorExtState state,
    ExtDokumen d,
  ) {
    final draft = state.drafts[d.id];
    return DokumenUploadCard(
      title: d.namaDokumen,
      requiredDoc: d.fileRequired,
      file: draft?.displayFile,
      onPick: () => _pick(context, ref, d.id),
      onPreview: () {
        final f = draft?.displayFile;
        if (f != null) _preview(context, f);
      },
      extraFields: (d.nomorRequired || d.tanggalRequired)
          ? NomorTanggalFields(
              showNomor: d.nomorRequired,
              showTanggal: d.tanggalRequired,
              nomor: draft?.nomor ?? '',
              tanggal: draft?.tanggal,
              onNomor: (v) =>
                  ref.read(auditorExtProvider(refExt).notifier).setNomor(d.id, v),
              onTanggal: () =>
                  _pickTanggal(context, ref, d.id, draft?.tanggal),
            )
          : null,
    );
  }
}