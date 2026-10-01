import '../../core/utils/api_response_utils.dart';

class InvoiceAuditorModel {
  final String namaAuditor;
  final int tagihanAuditor;
  final int? isNew;

  const InvoiceAuditorModel({
    required this.namaAuditor,
    required this.tagihanAuditor,
    this.isNew,
  });

  factory InvoiceAuditorModel.fromJson(Map<String, dynamic> json) {
    return InvoiceAuditorModel(
      namaAuditor: meaningfulString(json['nama_auditor']) ?? '-',
      tagihanAuditor: parseInt(json['tagihan_auditor']) ?? 0,
      isNew: parseInt(json['is_new']),
    );
  }
}

class InvoiceDetailModel {
  final String refInvoice;
  final String
      refLatik; // owner LATIK id (`ref_latik`), used by the billing request
  final String kode; // invoice number (`kode`), shown as "Tagihan {kode}"
  final String? kodeTagihan;
  final int isNew; // 1 = registration, else extension
  final String? name;
  final String? address;
  final String? phone;
  final String? email;
  final int tagihanLatik;
  final int tagihanTotal;
  final int?
      invoiceType; // null -> defaulted to 1 by the caller (LATIK row visible)
  final DateTime? tanggalTagihan; // issue date ("Diterbitkan")
  final DateTime?
      tanggalKadaluarsa; // due date ("Jatuh Tempo"); gates the billing request button
  final DateTime? tanggalPembayaran;
  final List<InvoiceAuditorModel> auditors;

  const InvoiceDetailModel({
    required this.refInvoice,
    required this.refLatik,
    required this.kode,
    this.kodeTagihan,
    required this.isNew,
    this.name,
    this.address,
    this.phone,
    this.email,
    required this.tagihanLatik,
    required this.tagihanTotal,
    this.invoiceType,
    this.tanggalTagihan,
    this.tanggalKadaluarsa,
    this.tanggalPembayaran,
    required this.auditors,
  });

  factory InvoiceDetailModel.fromJson(Map<String, dynamic> json) {
    final rawAuditors = json['auditors'];
    return InvoiceDetailModel(
      refInvoice: meaningfulString(json['ref_invoice']) ?? '',
      refLatik: meaningfulString(json['ref_latik']) ?? '',
      kode: meaningfulString(json['kode']) ?? '-',
      kodeTagihan: meaningfulString(json['kode_tagihan']),
      isNew: parseInt(json['is_new']) ?? 0,
      name: meaningfulString(json['name']),
      address: meaningfulString(json['address']),
      phone: meaningfulString(json['phone']),
      email: meaningfulString(json['email']),
      tagihanLatik: parseInt(json['tagihan_latik']) ?? 0,
      tagihanTotal: parseInt(json['tagihan_total']) ?? 0,
      invoiceType: parseInt(json['invoice_type']),
      tanggalTagihan: parseFlexibleDate(json['tanggal_tagihan']),
      tanggalKadaluarsa: parseFlexibleDate(json['tanggal_kadaluarsa']),
      tanggalPembayaran: parseFlexibleDate(json['tanggal_pembayaran']),
      auditors: rawAuditors is List
          ? rawAuditors
              .whereType<Map>()
              .map((e) =>
                  InvoiceAuditorModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}
