import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/invoice_model.dart';
import 'latik_service_provider.dart';

final invoiceListProvider =
    FutureProvider.autoDispose<List<InvoiceModel>>((ref) async {
  final rows = await ref.watch(latikServiceProvider).getInvoices();
  return rows
      .whereType<Map>()
      .map((e) => InvoiceModel.fromJson(Map<String, dynamic>.from(e)))
      .toList();
});
