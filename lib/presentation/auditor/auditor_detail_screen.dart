import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/auditor_model.dart';
import '../../providers/auditor_provider.dart';
import 'widgets/auditor_detail_actions.dart';
import 'widgets/auditor_detail_certificates.dart';
import 'widgets/auditor_detail_documents.dart';
import 'widgets/auditor_detail_extensions.dart';
import 'widgets/auditor_detail_header.dart';
import 'widgets/auditor_detail_profile_section.dart';
import 'widgets/detail_section.dart';

class AuditorDetailScreen extends ConsumerWidget {
  final AuditorModel auditor;
  const AuditorDetailScreen({super.key, required this.auditor});

  // ponytail: /latik/auditor/view tidak mengembalikan auditor_ext, jadi render
  // langsung dari item daftar (/latik/auditors) yang justru paling lengkap.
  AuditorModel get _auditor => auditor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(auditorDocsProvider(auditor.id)).valueOrNull;
    final docsCount =
        (docs == null || docs.isEmpty) ? null : '${docs.length} Berkas';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Auditor',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.spacing16, AppTheme.spacing16, AppTheme.spacing16, 32),
        children: [
          AuditorDetailHeader(auditor: _auditor),
          const SizedBox(height: AppTheme.spacing16),
          DetailSectionCard(
            title: 'Profil Auditor',
            child: AuditorDetailProfileSection(auditor: _auditor),
          ),
          const SizedBox(height: AppTheme.spacing12),
          DetailSectionCard(
            title: 'Sertifikat Pelatihan',
            countLabel: _auditor.certificates.isEmpty
                ? null
                : '${_auditor.certificates.length} Pelatihan',
            child: AuditorDetailCertificates(auditor: _auditor),
          ),
          const SizedBox(height: AppTheme.spacing12),
          DetailSectionCard(
            title: 'Dokumen',
            countLabel: docsCount,
            child: AuditorDetailDocuments(auditor: _auditor),
          ),
          const SizedBox(height: AppTheme.spacing12),
          DetailSectionCard(
            title: 'Perpanjangan',
            countLabel: _auditor.auditorExt.isEmpty
                ? null
                : '${_auditor.auditorExt.length} Riwayat',
            child: AuditorDetailExtensions(auditor: _auditor),
          ),
          const SizedBox(height: AppTheme.spacing24),
          AuditorDetailActions(auditor: _auditor),
        ],
      ),
    );
  }
}