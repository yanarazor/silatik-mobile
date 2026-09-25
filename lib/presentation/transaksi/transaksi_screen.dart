import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../data/models/invoice_model.dart';
import '../../providers/invoice_provider.dart';
import '../shared/error_retry.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/transaksi_filter_button.dart';
import 'widgets/transaction_card.dart';

class TransaksiScreen extends ConsumerStatefulWidget {
  const TransaksiScreen({super.key});

  @override
  ConsumerState<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends ConsumerState<TransaksiScreen> {
  // null = "Semua" (all).
  InvoiceStatus? _status;
  InvoiceType? _type;

  List<InvoiceModel> _apply(List<InvoiceModel> all) {
    return all.where((inv) {
      if (_status != null && inv.status != _status) return false;
      if (_type != null && inv.type != _type) return false;
      return true;
    }).toList();
  }

  bool get _hasActiveFilter => _status != null || _type != null;

  int get _activeFilterCount =>
      (_status != null ? 1 : 0) + (_type != null ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(invoiceListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Daftar Transaksi',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(invoiceListProvider);
            await ref.read(invoiceListProvider.future);
          },
          child: async.when(
            data: (all) => _buildList(all),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => ErrorRetry(
              message: 'Gagal memuat transaksi',
              scrollable: true,
              onRetry: () => ref.invalidate(invoiceListProvider),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<InvoiceModel> all) {
    final filtered = _apply(all);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _buildHeaderRow(filtered.length),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          _EmptyState(hasFilter: _hasActiveFilter)
        else
          ...filtered.map(
            (inv) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TransactionCard(
                invoice: inv,
                onTap: () => _openInvoice(inv),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderRow(int visibleCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Riwayat Tagihan',
                style: TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$visibleCount transaksi',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilterButton(
          activeCount: _activeFilterCount,
          onTap: _openFilterSheet,
        ),
      ],
    );
  }

  Future<void> _openInvoice(InvoiceModel inv) async {
    if (inv.ref.isEmpty) return;
    context.push(
      '${AppRoutes.pdfViewer}?ref=${Uri.encodeQueryComponent(inv.ref)}',
    );
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FilterSheet(status: _status, type: _type),
    );
    if (result != null && mounted) {
      setState(() {
        _status = result.status;
        _type = result.type;
      });
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 72),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 48,
            color: const Color(0xFF94A3B8).withValues(alpha: 0.8),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tidak Ada Transaksi',
            style: TextStyle(
              color: Color(0xFF1A1A2E),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasFilter
                ? 'Tidak ada transaksi yang cocok dengan filter yang dipilih.'
                : 'Belum ada transaksi tercatat.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}