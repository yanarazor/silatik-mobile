import 'package:flutter/material.dart';

import '../../../data/models/auditor_model.dart';
import '../../../data/models/latik_ext_model.dart';
import '../../../data/models/registrasi_model.dart';
import '../../../providers/latik_ext_provider.dart' show ExtDokumenDraft;
import '../../shared/revisi_dokumen_card.dart';
import 'revisi_bottom_actions.dart';

/// Grouped per-auditor correction documents with save/submit footer.
class AuditorRevisionDocsStep extends StatelessWidget {
  const AuditorRevisionDocsStep({
    super.key,
    required this.auditors,
    required this.docsByAuditor,
    required this.drafts,
    required this.hasUnsavedEdits,
    required this.isSaving,
    required this.isSubmitting,
    required this.onPickFile,
    required this.onPreviewFile,
    required this.onNomorChanged,
    required this.onTanggalPicked,
    required this.onSave,
    required this.onSubmit,
  });

  final List<AuditorModel> auditors;
  final Map<String, List<ExtDokumen>> docsByAuditor;
  final Map<int, ExtDokumenDraft> drafts;
  final bool hasUnsavedEdits;
  final bool isSaving;
  final bool isSubmitting;
  final ValueChanged<int> onPickFile;
  final ValueChanged<FileItem> onPreviewFile;
  final void Function(int docId, String value) onNomorChanged;
  final void Function(int docId, DateTime? current) onTanggalPicked;
  final VoidCallback onSave;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              if (hasUnsavedEdits) _unsavedBanner(),
              for (final auditor in auditors) ...[
                _auditorHeader(auditor),
                const SizedBox(height: 10),
                for (final doc in (docsByAuditor[auditor.id] ?? []))
                  if (drafts[doc.id] case final draft?)
                    RevisiDokumenCard(
                      key: ValueKey('${auditor.id}_${doc.id}'),
                      title: doc.namaDokumen,
                      statusVerifikasi: doc.statusVerifikasi,
                      catatanVerifikasi: doc.catatanVerifikasi,
                      fileRequired: doc.fileRequired,
                      nomorRequired: doc.nomorRequired,
                      tanggalRequired: doc.tanggalRequired,
                      nomor: draft.nomor,
                      tanggal: draft.tanggal,
                      fileUrl: doc.fileUrl,
                      localFile: draft.file,
                      onPick: () => onPickFile(doc.id),
                      onPreview: () {
                        final file = draft.displayFile;
                        if (file != null) onPreviewFile(file);
                      },
                      onNomorChanged: (value) => onNomorChanged(doc.id, value),
                      onTanggalPicked: () =>
                          onTanggalPicked(doc.id, draft.tanggal),
                    ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
        RevisiBottomActions(
          isSaving: isSaving,
          isSubmitting: isSubmitting,
          onSave: onSave,
          onSubmit: onSubmit,
        ),
      ],
    );
  }

  Widget _unsavedBanner() => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_rounded, color: Color(0xFFD97706), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Terdapat perbaikan dokumen yang belum disimpan. Tekan Simpan di bawah.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _auditorHeader(AuditorModel auditor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0C2D5C),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                auditor.nama,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
}
