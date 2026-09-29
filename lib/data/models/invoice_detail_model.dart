import '../../core/utils/api_response_utils.dart';

class InvoiceAuditorModel {
  final String namaAuditor;
  final int tagihanAuditor;

  const InvoiceAuditorModel({required this.namaAuditor, required this.tagihanAuditor});

  factory InvoiceAuditorModel.fromJson(Map<String, dynamic> json) {
    return InvoiceAuditorModel(
      namaAuditor: meaningfulString(json['nama_auditor']) ?? '-',
      tagihanAuditor: parseInt(json['tagihan_auditor']) ?? 0,
    );
  }
}

class InvoiceDetailModel {
  final String refInvoicice; // canonical id (`ref_invoice`)
  final String refLatik; // owner LATIK id (`ref_latik`), used by the billing request
  final String kode; // invoice number (`kode`), shown as "Tagihan {kode}"
  final int isNew; // 1 = registration, else extension (drives the LATIK row label + tariff)
  final String? name;
  final String? address;
  final String? phone;
  final String? email;
  final int tagihanTotal;
  final int? invoiceType; // null -> defaulted to 1 by the caller (LATIK row visible)
  final DateTime? tanggalTagihan; // issue date ("Diterbitkan")
  final DateTime? tanggalKadaluarsa; // due date ("Jatuh Tempo"); gates the billing request button
  final List<InvoiceAuditorModel> auditors;

  const InvoiceDetailModel({
    required this.refInvoicice,
    required this.refLatik,
    required this.kode,
    required this.isNew,
    this.name,
    this.address,
    this.phone,
    this.email,
    required this.tagihanTotal,
    this.invoiceType,
    this.tanggalTagihan,
    this.tanggalKadaluarsa,
    required this.auditors,
  });

  factory InvoiceDetailModel.fromJson(Map<String, dynamic> json) {
    final rawAuditors = json['auditors'];
    return InvoiceDetailModel(
      refInvoicice: meaningfulString(json['ref_invoice']) ?? '',
      refLatik: meaningfulString(json['ref_latik']) ?? '',
      kode: meaningfulString(json['kode']) ?? '-',
      isNew: parseInt(json['is_new']) ?? 0,
      name: meaningfulString(json['name']),
      address: meaningfulString(json['address']),
      phone: meaningfulString(json['phone']),
      email: meaningfulString(json['email']),
      tagihanTotal: parseInt(json['tagihan_total']) ?? 0,
      invoiceType: parseInt(json['invoice_type']),
      tanggalTagihan: parseFlexibleDate(json['tanggal_tagihan']),
      tanggalKadaluarsa: parseFlexibleDate(json['tanggal_kadaluarsa']),
      auditors: rawAuditors is List
          ? rawAuditors
                .whereType<Map>()
                .map((e) => InvoiceAuditorModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }

  static final sample = InvoiceDetailModel.fromJson({
    'ref_invoice': 'bfcdfc5b-0082-4f90-b524-0b82c98f1927',
    'ref_latik': '3d1bf16c-3b5d-49ba-a2ba-39526a081862',
    'kode': 'L12025041539910',
    'is_new': 1,
    'name': 'Testing DS Silatik',
    'address': 'Jalan testing no.10',
    'phone': '089111222336',
    'email': 'venniesadhevanty@gmail.com',
    'tagihan_total': 6000000,
    'invoice_type': null,
    'tanggal_tagihan': '2025-07-15 16:34:14',
    'tanggal_kadaluarsa': '2025-07-22 23:59:59',
    'auditors': [
      {'nama_auditor': 'Mega Puspitasari', 'tagihan_auditor': 0},
      {'nama_auditor': 'Venniesa Dhevanty', 'tagihan_auditor':  1000000},
    ],
  });
}