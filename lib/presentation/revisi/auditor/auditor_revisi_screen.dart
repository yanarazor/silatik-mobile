import 'package:flutter/material.dart';

import '../widgets/auditor_revision_flow_screen.dart';

/// Flow 2: returned auditor extension applications.
class AuditorRevisiScreen extends StatelessWidget {
  const AuditorRevisiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuditorRevisionFlowScreen(
      title: 'Revisi Perpanjangan Auditor',
      submitTitle: 'Ajukan Revisi Auditor',
      successMessage: 'Revisi perpanjangan auditor berhasil diajukan!',
      emptyMessage:
          'Semua pengajuan perpanjangan auditor telah valid atau tidak memerlukan perbaikan.',
      isAddAuditor: false,
    );
  }
}
