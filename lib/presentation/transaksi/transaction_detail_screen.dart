import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/api_error_handler.dart';
import '../../data/models/invoice_detail_model.dart';
import '../../providers/invoice_detail_provider.dart';
import '../../providers/latik_service_provider.dart';
import '../shared/error_retry.dart';
import 'widgets/transaction_detail_widgets.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  bool _requesting = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(invoiceDetailProvider(widget.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Detail Transaksi',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorRetry(
          message: 'Gagal memuat detail transaksi',
          onRetry: () => ref.invalidate(invoiceDetailProvider(widget.id)),
        ),
        data: (model) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TransactionInvoiceDocument(invoice: model),
            const SizedBox(height: AppTheme.spacing24),
            _buildActions(model),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(InvoiceDetailModel model) {
    final due = model.tanggalKadaluarsa;
    final paid = model.tanggalPembayaran != null;
    final billingDisabled =
        _requesting || paid || (due != null && due.isAfter(DateTime.now()));

    return Column(
      children: [
        SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _openInvoice(model),
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
        if (!paid) ...[
          const SizedBox(height: AppTheme.spacing12),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: billingDisabled ? null : () => _requestBilling(model),
              icon: _requesting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 20),
              label: const Text(
                'Request Kode Billing',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(
                  billingDisabled ? const Color(0xFF9CA3AF) : AppColors.primary,
                ),
                iconColor: WidgetStatePropertyAll(
                  billingDisabled ? const Color(0xFF9CA3AF) : AppColors.primary,
                ),
                side: WidgetStatePropertyAll(
                  BorderSide(
                    color: billingDisabled
                        ? const Color(0xFFD1D5DB)
                        : AppColors.primary,
                  ),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  ),
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
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _openInvoice(InvoiceDetailModel model) {
    if (model.refInvoice.isEmpty) return;
    context.push(
      '${AppRoutes.pdfViewer}?ref=${Uri.encodeQueryComponent(model.refInvoice)}',
    );
  }

  Future<void> _requestBilling(InvoiceDetailModel model) async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      await ref
          .read(latikServiceProvider)
          .getBilling(model.refInvoice, refLatik: model.refLatik);
      ref.invalidate(invoiceDetailProvider(widget.id));
    } catch (e) {
      if (!mounted) return;
      final message = e is DioException
          ? ApiErrorHandler.getMessage(e)
          : 'Terjadi kesalahan membuat billing';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }
}
