import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/profil_dokumen.dart';
import 'doc_edit.dart';

/// Optional nomor / tanggal inputs for one document, shown below its upload
/// card when the document definition requires them.
class DocExtraFields extends StatelessWidget {
  const DocExtraFields({
    super.key,
    required this.doc,
    required this.edit,
    required this.onPickDate,
  });

  final ProfilDokumen doc;
  final DocEdit edit;
  final void Function(int id, DateTime? current) onPickDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (doc.nomorRequired) ...[
            const _FieldLabel('Nomor Dokumen', required: true),
            const SizedBox(height: 6),
            TextField(
              controller: edit.nomor,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              decoration: const InputDecoration(
                hintText: 'Nomor dokumen',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
          ],
          if (doc.tanggalRequired) ...[
            if (doc.nomorRequired) const SizedBox(height: AppTheme.spacing12),
            const _FieldLabel('Tanggal Dokumen', required: true),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => onPickDate(doc.id!, edit.tanggal),
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  edit.tanggal == null
                      ? 'Pilih tanggal'
                      : AppFormatters.formatShortDate(edit.tanggal),
                  style: TextStyle(
                    color: edit.tanggal == null
                        ? Theme.of(context).hintColor
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.required});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        children: required
            ? const [
                TextSpan(text: ' *', style: TextStyle(color: AppColors.error))
              ]
            : const [],
      ),
    );
  }
}