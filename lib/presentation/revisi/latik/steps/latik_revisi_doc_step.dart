import 'package:flutter/material.dart';

import '../../../shared/revisi_dokumen_card.dart';
import '../../../../providers/latik_revisi_provider.dart';
import '../../../../data/models/registrasi_model.dart';
import '../../widgets/revisi_bottom_actions.dart';

/// Step 2: Document correction list with save/submit action footer.
class LatikRevisiDocStep extends StatelessWidget {
  const LatikRevisiDocStep({
    super.key,
    required this.docs,
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

  final List<RevisiDokumenDraft> docs;
  final bool hasUnsavedEdits;
  final bool isSaving;
  final bool isSubmitting;
  final ValueChanged<int> onPickFile;
  final ValueChanged<FileItem> onPreviewFile;
  final void Function(int id, String val) onNomorChanged;
  final void Function(int id, DateTime? current) onTanggalPicked;
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
              if (hasUnsavedEdits)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_rounded,
                          color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Anda memiliki perubahan yang belum disimpan. Tekan tombol "Simpan" di bawah.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              for (final doc in docs)
                RevisiDokumenCard(
                  key: ValueKey(doc.def.id),
                  title: doc.def.namaDokumen,
                  statusVerifikasi: doc.def.statusVerifikasi,
                  catatanVerifikasi: doc.def.catatanVerifikasi,
                  fileRequired: doc.def.fileRequired,
                  nomorRequired: doc.def.nomorRequired,
                  tanggalRequired: doc.def.tanggalRequired,
                  nomor: doc.nomor,
                  tanggal: doc.tanggal,
                  fileUrl: doc.def.fileUrl,
                  localFile: doc.file,
                  onPick: () => onPickFile(doc.def.id),
                  onPreview: () {
                    final file = doc.displayFile;
                    if (file != null) onPreviewFile(file);
                  },
                  onNomorChanged: (v) => onNomorChanged(doc.def.id, v),
                  onTanggalPicked: () =>
                      onTanggalPicked(doc.def.id, doc.tanggal),
                ),
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
}
