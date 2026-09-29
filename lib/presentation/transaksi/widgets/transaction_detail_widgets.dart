import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/invoice_detail_model.dart';

class TransactionDetailHeaderCard extends StatelessWidget {
  const TransactionDetailHeaderCard({super.key, required this.invoice});

  final InvoiceDetailModel invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/brin.png',
                width: 50,
                height:  50,
              ),
              const SizedBox(width: 12),
              const Expanded(child: _BrandBlock()),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tagihan ${invoice.kode}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              // Copy is pointless for the missing-kode dash, so hide it then.
              if (invoice.kode != '-')
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: invoice.kode));
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(content: Text('Nomor tagihan disalin')));
                  },
                  tooltip: 'Salin nomor tagihan',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.copy, size: 16, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 4),
          _MetaLine(label: 'Diterbitkan', value: AppFormatters.formatDate(invoice.tanggalTagihan)),
          _MetaLine(label: 'Jatuh Tempo', value: AppFormatters.formatDate(invoice.tanggalKadaluarsa)),
        ],
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Badan Riset dan Inovasi Nasional',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        SizedBox(height: 6),
        _BrandLine('Gedung B.J. Habibie, Jl. M.H. Thamrin No. 8'),
        _BrandLine('Jakarta Pusat 10340'),
        _BrandLine('Whatsapp: +62811-1933-3639'),
        _BrandLine('Email: ppid@brin.go.id'),
      ],
    );
  }
}

class _BrandLine extends StatelessWidget {
  const _BrandLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class TransactionDetailBilledPartyCard extends StatelessWidget {
  const TransactionDetailBilledPartyCard({super.key, required this.invoice});

  final InvoiceDetailModel invoice;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tertagih', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          Text(invoice.name ?? '-', style: const TextStyle(fontSize: 13)),
          Text(invoice.address ?? '-', style: const TextStyle(fontSize: 13)),
          Text(invoice.phone ?? '-', style: const TextStyle(fontSize: 13)),
          Text(invoice.email ?? '-', style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class TransactionDetailTagihanCard extends StatelessWidget {
  const TransactionDetailTagihanCard({super.key, required this.invoice});

  final InvoiceDetailModel invoice;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tagihan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Jumlah Tagihan:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const Spacer(),
              Text(
                AppFormatters.formatRupiah(invoice.tagihanTotal),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TransactionDetailLineItemsCard extends StatelessWidget {
  const TransactionDetailLineItemsCard({super.key, required this.invoice});

  final InvoiceDetailModel invoice;

  @override
  Widget build(BuildContext context) {
    final invoiceType = invoice.invoiceType ?? 1;
    final showLatikRow = invoiceType ==  1 || invoiceType ==  2;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const _TableRow(label: 'Item', tariff: 'Tarif', header: true),
          if (showLatikRow) ...[
            const Divider(height: 1),
            _TableRow(label: _latikLabel(invoice), tariff: _latikTariff(invoice)),
          ],
          for (final auditor in invoice.auditors) ...[
            const Divider(height: 1),
            _TableRow(
              label: _auditorLabel(invoice, auditor),
              tariff: AppFormatters.formatRupiah(auditor.tagihanAuditor),
            ),
          ],
        ],
      ),
    );
  }

  static String _latikLabel(InvoiceDetailModel invoice) {
    return invoice.isNew ==  1
        ? 'Verifikasi Registrasi - LATIK - ${invoice.name ?? '-'}'
        : 'Verifikasi Perpanjangan - LATIK - ${invoice.name ?? '-'}';
  }

  static String _latikTariff(InvoiceDetailModel invoice) {

    return AppFormatters.formatRupiah(invoice.isNew ==  1 ? 5000000 : 3750000);
  }

  static String _auditorLabel(InvoiceDetailModel invoice, InvoiceAuditorModel auditor) {

    final String prefix;



    if (invoice.invoiceType ==  4) {
      prefix = 'Verifikasi Perpanjangan - Auditor - ';
    } else if (invoice.invoiceType ==  5) {
      prefix = 'Verifikasi Penambahan Auditor - ';
    } else {
      prefix = 'Verifikasi Registrasi - Auditor - ';
    }
    return '$prefix${auditor.namaAuditor}';
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.label, required this.tariff, this.header = false});

  final String label;
  final String tariff;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical:  12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: header ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            tariff,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize:  13,
              color: header ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionDetailFooterCard extends StatelessWidget {
  const TransactionDetailFooterCard({super.key, required this.invoice});

  final InvoiceDetailModel invoice;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Terima kasih sudah mempercayakan SILATIK',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Total:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Text(
                AppFormatters.formatRupiah(invoice.tagihanTotal),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}