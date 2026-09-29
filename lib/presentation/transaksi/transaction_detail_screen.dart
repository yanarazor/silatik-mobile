import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/invoice_detail_model.dart';
import 'widgets/transaction_detail_widgets.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends ConsumerState<TransactionDetailScreen> {
  void _previewSnack(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label: menunggu integrasi data')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Detail Transaksi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          TransactionDetailHeaderCard(invoice: InvoiceDetailModel.sample),
          const SizedBox(height: AppTheme.spacing16),
          TransactionDetailBilledPartyCard(invoice: InvoiceDetailModel.sample),
          const SizedBox(height: AppTheme.spacing12),
          TransactionDetailTagihanCard(invoice: InvoiceDetailModel.sample),
          const SizedBox(height: AppTheme.spacing12),
          TransactionDetailLineItemsCard(invoice: InvoiceDetailModel.sample),
          const SizedBox(height: AppTheme.spacing12),
          TransactionDetailFooterCard(invoice: InvoiceDetailModel.sample),
          const SizedBox(height: AppTheme.spacing24),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _previewSnack('Lihat Invoice'),
            icon: const Icon(Icons.picture_as_pdf, size: 20),
            label: const Text(
              'Lihat Invoice',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _previewSnack('Request Kode Billing'),
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text(
              'Request Kode Billing',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 14, color: AppColors.warning),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                'Tombol aktif setelah melewati tanggal jatuh tempo',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}