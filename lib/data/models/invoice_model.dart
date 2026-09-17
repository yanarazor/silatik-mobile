import '../../core/utils/api_response_utils.dart';

/// Payment status of an invoice (`status` field on listinvoices).
enum InvoiceStatus { terhutang, lunas, kadaluarsa, lainnya }

/// Transaction type of an invoice (`invoice_type` field on listinvoices).
enum InvoiceType {
  registrasiLatik,
  perpanjanganLatik,
  registrasiAuditor,
  perpanjanganAuditor,
  penambahanAuditor,
}

/// One LATIK invoice/transaction from GET /latik/listinvoices.
class InvoiceModel {
  final String ref;
  final String kode; // invoice number shown to the user
  final String kodeTagihan; // billing/VA code the user pays against ('' if none)
  final String namaLatik;
  final int tagihanTotal;
  final int tagihanLatik;
  final int tagihanAuditor;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final InvoiceStatus status;
  final InvoiceType type;

  const InvoiceModel({
    required this.ref,
    required this.kode,
    required this.kodeTagihan,
    required this.namaLatik,
    required this.tagihanTotal,
    required this.tagihanLatik,
    required this.tagihanAuditor,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.type,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      ref: (json['ref'] ?? '').toString(),
      kode: meaningfulString(json['kode']) ?? '-',
      kodeTagihan: meaningfulString(json['kode_tagihan']) ?? '',
      namaLatik: meaningfulString(json['nama_latik']) ?? '-',
      tagihanTotal: parseInt(json['tagihan_total']) ?? 0,
      tagihanLatik: parseInt(json['tagihan_latik']) ?? 0,
      tagihanAuditor: parseInt(json['tagihan_auditor']) ?? 0,
      createdAt: parseFlexibleDate(json['created_at']),
      updatedAt: parseFlexibleDate(json['updated_at']),
      status: statusFromCode(parseInt(json['status'])),
      type: typeFromCode(parseInt(json['invoice_type'])),
    );
  }

  // status: 1 owed, 2 paid, 99 expired (per TRANSACTION_LATIK_LIST brief).
  static InvoiceStatus statusFromCode(int? code) {
    switch (code) {
      case 1:
        return InvoiceStatus.terhutang;
      case 2:
        return InvoiceStatus.lunas;
      case 99:
        return InvoiceStatus.kadaluarsa;
      default:
        return InvoiceStatus.lainnya;
    }
  }

  // invoice_type: 1 reg LATIK, 2 perp LATIK, 3 reg auditor, 4 perp auditor,
  // 5 penambahan auditor. Unknown/null falls back to Registrasi LATIK.
  static InvoiceType typeFromCode(int? code) {
    switch (code) {
      case 2:
        return InvoiceType.perpanjanganLatik;
      case 3:
        return InvoiceType.registrasiAuditor;
      case 4:
        return InvoiceType.perpanjanganAuditor;
      case 5:
        return InvoiceType.penambahanAuditor;
      case 1:
      default:
        return InvoiceType.registrasiLatik;
    }
  }
}

extension InvoiceStatusX on InvoiceStatus {
  String get label => switch (this) {
        InvoiceStatus.terhutang => 'Terhutang',
        InvoiceStatus.lunas => 'Lunas',
        InvoiceStatus.kadaluarsa => 'Kadaluarsa',
        InvoiceStatus.lainnya => '-',
      };

  /// Server code used for the `status` query param; null = no filter.
  int? get code => switch (this) {
        InvoiceStatus.terhutang => 1,
        InvoiceStatus.lunas => 2,
        InvoiceStatus.kadaluarsa => 99,
        InvoiceStatus.lainnya => null,
      };
}

extension InvoiceTypeX on InvoiceType {
  String get label => switch (this) {
        InvoiceType.registrasiLatik => 'Registrasi LATIK',
        InvoiceType.perpanjanganLatik => 'Perpanjangan LATIK',
        InvoiceType.registrasiAuditor => 'Registrasi Auditor',
        InvoiceType.perpanjanganAuditor => 'Perpanjangan Auditor',
        InvoiceType.penambahanAuditor => 'Penambahan Auditor',
      };

  /// Server code used for the `jenis_transaksi` query param.
  int get code => switch (this) {
        InvoiceType.registrasiLatik => 1,
        InvoiceType.perpanjanganLatik => 2,
        InvoiceType.registrasiAuditor => 3,
        InvoiceType.perpanjanganAuditor => 4,
        InvoiceType.penambahanAuditor => 5,
      };
}
