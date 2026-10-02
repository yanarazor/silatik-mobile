import 'package:flutter/material.dart';

import '../widgets/auditor_revision_flow_screen.dart';

/// Flow 3: returned add-auditor applications.
class AuditorAddRevisiScreen extends StatelessWidget {
  const AuditorAddRevisiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuditorRevisionFlowScreen(
      title: 'Revisi Penambahan Auditor',
      submitTitle: 'Ajukan Revisi Penambahan Auditor',
      successMessage: 'Revisi penambahan auditor berhasil diajukan!',
      emptyMessage:
          'Tidak ada pengajuan penambahan auditor yang memerlukan revisi.',
      isAddAuditor: true,
    );
  }
}
