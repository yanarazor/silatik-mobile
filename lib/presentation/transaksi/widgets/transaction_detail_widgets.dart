import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/invoice_detail_model.dart';
import 'transaction_invoice_items.dart';

const _ink = Color(0xFF20242A);
const _muted = Color(0xFF626A73);
const _paper = Color(0xFFFFFFFF);

class TransactionInvoiceDocument extends StatelessWidget {
  const TransactionInvoiceDocument({super.key, required this.invoice});

  final InvoiceDetailModel invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _paper,
        border: Border.all(color: const Color(0xFFE1E4E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InvoiceHeading(invoice: invoice),
          const SizedBox(height: 22),
          _BillTo(invoice: invoice),
          const SizedBox(height: 22),
          TransactionInvoiceItems(invoice: invoice),
          const SizedBox(height: 20),
          _PaymentInformation(invoice: invoice),
          const SizedBox(height: 16),
          const _PnbpNote(),
        ],
      ),
    );
  }
}

class _InvoiceHeading extends StatelessWidget {
  const _InvoiceHeading({required this.invoice});

  final InvoiceDetailModel invoice;

  @override
  Widget build(BuildContext context) {
    final paid = invoice.tanggalPembayaran != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset('assets/images/brin.png', width: 46, height: 46),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BRIN',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 20,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'BADAN RISET DAN INOVASI NASIONAL',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 8,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, color: _ink, thickness: 1.2),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
                child: _DocumentValueRow(
                    label: 'Nomor Tagihan', value: invoice.kode)),
            if (invoice.kode != '-')
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: invoice.kode));
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                        const SnackBar(content: Text('Nomor tagihan disalin')));
                },
                tooltip: 'Salin nomor tagihan',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy, size: 16, color: _muted),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          paid
              ? 'Status Pembayaran: SUDAH DIBAYAR (PAID)'
              : 'Status Pembayaran: BELUM DIBAYAR (UNPAID)',
          style: TextStyle(
            color: paid ? AppColors.success : AppColors.error,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _BillTo extends StatelessWidget {
  const _BillTo({required this.invoice});

  final InvoiceDetailModel invoice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kepada:',
            style: TextStyle(
                color: _ink, fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        _DocumentValueRow(label: 'Nama', value: _value(invoice.name)),
        _DocumentValueRow(label: 'Alamat', value: _value(invoice.address)),
        _DocumentValueRow(label: 'Telpon', value: _value(invoice.phone)),
        _DocumentValueRow(label: 'Email', value: _value(invoice.email)),
      ],
    );
  }
}

class _PaymentInformation extends StatelessWidget {
  const _PaymentInformation({required this.invoice});

  final InvoiceDetailModel invoice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, color: _ink, thickness: 1),
        const SizedBox(height: 10),
        _DocumentValueRow(
            label: 'Kode Billing', value: _value(invoice.kodeTagihan)),
        _DocumentValueRow(
            label: 'Issue Date',
            value: _formatDateTime(invoice.tanggalTagihan)),
        _DocumentValueRow(
            label: 'Exp Date',
            value: _formatDateTime(invoice.tanggalKadaluarsa)),
        _DocumentValueRow(
          label: 'Total Tagihan',
          value: AppFormatters.formatRupiah(invoice.tagihanTotal),
          bold: true,
        ),
      ],
    );
  }
}

class _PnbpNote extends StatelessWidget {
  const _PnbpNote();

  @override
  Widget build(BuildContext context) => const Text(
        'Catatan: Pembayaran merupakan PNBP (Penerimaan Negara Bukan Pajak) dan tidak dikenakan pajak.',
        style: TextStyle(color: _muted, fontSize: 9, height: 1.4),
      );
}

class _DocumentValueRow extends StatelessWidget {
  const _DocumentValueRow(
      {required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Text(
                label,
                style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
              ),
            ),
            const Text(': ', style: TextStyle(color: _muted, fontSize: 10)),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                    color: _ink,
                    fontSize: 10,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                    height: 1.35),
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

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(value);
}
