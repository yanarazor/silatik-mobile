import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/invoice_detail_model.dart';
import 'latik_service_provider.dart';

final invoiceDetailProvider =
    FutureProvider.autoDispose.family<InvoiceDetailModel, String>((ref, id) async {
  final data = await ref.watch(latikServiceProvider).getInvoiceText(id);
  return InvoiceDetailModel.fromJson(data);
});
