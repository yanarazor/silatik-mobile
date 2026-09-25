import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/profil_dokumen.dart';
import 'doc_card.dart';
import 'filter_chip.dart';
import 'summary_card.dart';

/// Filterable document list body.
class DocsView extends StatefulWidget {
  const DocsView({super.key, required this.docs});

  final List<ProfilDokumen> docs;

  @override
  State<DocsView> createState() => _DocsViewState();
}

class _DocsViewState extends State<DocsView> {
  BerkasFilter _filter = BerkasFilter.semua;

  @override
  Widget build(BuildContext context) {
    final verified = widget.docs.where((d) => d.terverifikasi).length;
    final pending = widget.docs.length - verified;
    final visible = widget.docs.where((d) {
      switch (_filter) {
        case BerkasFilter.semua:
          return true;
        case BerkasFilter.terverifikasi:
          return d.terverifikasi;
        case BerkasFilter.belum:
          return !d.terverifikasi;
      }
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        SummaryCard(
          total: widget.docs.length,
          verified: verified,
          pending: pending,
          filter: _filter,
          onFilter: (f) => setState(() => _filter = f),
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          EmptyDocs(
            message: widget.docs.isEmpty
                ? 'Belum ada dokumen kelengkapan'
                : 'Tidak ada dokumen pada kategori ini',
          )
        else
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            DocCard(doc: visible[i]),
          ],
      ],
    );
  }
}

/// Empty state for the document list.
class EmptyDocs extends StatelessWidget {
  const EmptyDocs({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          const Icon(
            Icons.folder_off_outlined,
            size: 44,
            color: Color(0xFFB4BDCC),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}