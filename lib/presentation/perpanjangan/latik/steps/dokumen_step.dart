import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/registrasi_model.dart';
import '../../../../providers/latik_ext_provider.dart';
import '../../../shared/dokumen_upload_card.dart';
import '../../../shared/widgets/nomor_tanggal_fields.dart';

/// Langkah 1 — unggah dokumen persyaratan. Kartu dinamis dari backend; input
/// Nomor/Tanggal disisipkan lewat `extraFields` sesuai flag per dokumen.
class DokumenStep extends StatelessWidget {
  const DokumenStep({
    super.key,
    required this.state,
    required this.onPick,
    required this.onPreview,
    required this.onNomor,
    required this.onTanggal,
    required this.onBack,
    required this.onNext,
  });

  final LatikExtState state;
  final void Function(int id) onPick;
  final void Function(FileItem doc) onPreview;
  final void Function(int id, String value) onNomor;
  final void Function(int id, DateTime? current) onTanggal;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.submitting && state.dokumen.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.dokumen.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            state.error != null
                ? 'Gagal memuat dokumen.\n${state.error}'
                : 'Belum ada dokumen persyaratan.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: ListView(
        children: [
          Text(
            'Dokumen Pendukung',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Unggah dokumen persyaratan perpanjangan (PDF, maks 10MB).',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacing16),
          for (final d in state.dokumen) ...[
            DokumenUploadCard(
              title: d.def.namaDokumen,
              requiredDoc: d.def.fileRequired,
              file: d.displayFile,
              onPick: () => onPick(d.def.id),
              onPreview: () {
                final f = d.displayFile;
                if (f != null) onPreview(f);
              },
              extraFields: (d.def.nomorRequired || d.def.tanggalRequired)
                  ? NomorTanggalFields(
                      showNomor: d.def.nomorRequired,
                      showTanggal: d.def.tanggalRequired,
                      nomor: d.nomor,
                      tanggal: d.tanggal,
                      onNomor: (v) => onNomor(d.def.id, v),
                      onTanggal: () => onTanggal(d.def.id, d.tanggal),
                    )
                  : null,
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
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
                  child: const Text('Lanjut'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}