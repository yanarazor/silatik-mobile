import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/invoice_detail_model.dart';

const _ink = Color(0xFF20242A);
const _muted = Color(0xFF626A73);
const _rule = Color(0xFFD4D8DE);

class TransactionInvoiceItems extends StatelessWidget {
  const TransactionInvoiceItems({super.key, required this.invoice});

  final InvoiceDetailModel invoice;

  @override
  Widget build(BuildContext context) {
    final rows = <_InvoiceItemData>[];
    final type = invoice.invoiceType ?? 1;
    if (type == 1 || type == 2) {
      final isNew = invoice.isNew == 1;
      rows.add(
        _InvoiceItemData(
          title: isNew
              ? 'Verifikasi Registrasi - LATIK'
              : 'Verifikasi Perpanjangan - LATIK',
          subtitle: _value(invoice.name),
          amount: isNew ? 5000000 : 3750000,
        ),
      );
    }

    for (final auditor in invoice.auditors) {
      rows.add(
        _InvoiceItemData(
          title:
              'Verifikasi ${type == 5 ? 'Penambahan' : type == 4 ? 'Perpanjangan' : 'Registrasi'} - Auditor',
          subtitle: 'a.n. ${auditor.namaAuditor}',
          amount: auditor.tagihanAuditor,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TableHeader(),
        for (final row in rows) _TableRow(item: row),
        _TotalRow(total: invoice.tagihanTotal),
      ],
    );
  }
}

class _InvoiceItemData {
  const _InvoiceItemData(
      {required this.title, required this.subtitle, required this.amount});

  final String title;
  final String subtitle;
  final int amount;
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
            border: Border(top: BorderSide(color: _ink, width: 1.1))),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text('Deskripsi',
                    style: TextStyle(
                        color: _ink,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
              SizedBox(
                width: 86,
                child: Text('Jumlah',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        color: _ink,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      );
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.item});

  final _InvoiceItemData item;

  @override
  Widget build(BuildContext context) => Container(
        decoration:
            const BoxDecoration(border: Border(top: BorderSide(color: _rule))),
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          color: _ink,
                          fontSize: 10,
                          height: 1.35,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(item.subtitle,
                      style: const TextStyle(
                          color: _muted, fontSize: 9, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 86,
              child: Text(
                AppFormatters.formatRupiah(item.amount),
                textAlign: TextAlign.end,
                style: const TextStyle(color: _ink, fontSize: 10, height: 1.35),
              ),
            ),
          ],
        ),
      );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
            border: Border.symmetric(
                horizontal: BorderSide(color: _ink, width: 1.1))),
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            const Expanded(
              child: Text('Total',
                  style: TextStyle(
                      color: _ink, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
            SizedBox(
              width: 86,
              child: Text(
                AppFormatters.formatRupiah(total),
                textAlign: TextAlign.end,
                style: const TextStyle(
                    color: _ink, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
}

String _value(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? '-' : trimmed;
}
