import '../../core/utils/api_response_utils.dart';

/// Invoice attached to an auditor extension request.
class AuditorExtInvoice {
  final String kodeTagihan;
  final String kode;
  final int? tagihanTotal;
  final int? status;

  const AuditorExtInvoice({
    required this.kodeTagihan,
    required this.kode,
    this.tagihanTotal,
    this.status,
  });

  factory AuditorExtInvoice.fromJson(Map<String, dynamic> json) {
    return AuditorExtInvoice(
      kodeTagihan: (json['kode_tagihan'] ?? '').toString(),
      kode: (json['kode'] ?? '').toString(),
      tagihanTotal: _toInt(json['tagihan_total'] ?? json['tagihan_auditor']),
      status: _toInt(json['status']),
    );
  }

  static int? _toInt(dynamic value) => parseInt(value);

  Map<String, dynamic> toJson() => {
        'kode_tagihan': kodeTagihan,
        'kode': kode,
        'tagihan_total': tagihanTotal,
        'status': status,
      };
}

/// One auditor extension history record from /latik/auditors.
class AuditorExtension {
  final String ref;
  final String auditorRef;
  final String latikExt;
  final int? status;
  final int? statusVerifikasi;
  final String catatanVerifikasi;
  final DateTime? strTanggalAwal;
  final DateTime? strTanggalAkhir;
  final AuditorExtInvoice? invoice;

  const AuditorExtension({
    required this.ref,
    required this.auditorRef,
    required this.latikExt,
    this.status,
    this.statusVerifikasi,
    this.catatanVerifikasi = '',
    this.strTanggalAwal,
    this.strTanggalAkhir,
    this.invoice,
  });

  factory AuditorExtension.fromJson(Map<String, dynamic> json) {
    final invoices = json['paid_ext_invoice'];
    AuditorExtInvoice? invoice;
    if (invoices is List) {
      for (final item in invoices.whereType<Map>()) {
        invoice = AuditorExtInvoice.fromJson(Map<String, dynamic>.from(item));
        break;
      }
    }
    return AuditorExtension(
      ref: (json['ref'] ?? json['id'] ?? '').toString(),
      auditorRef: (json['auditor_ref'] ?? '').toString(),
      latikExt: (json['latik_ext'] ?? '').toString(),
      status: _toInt(json['status']),
      statusVerifikasi: _toInt(json['status_verifikasi']),
      catatanVerifikasi: (json['catatan_verifikasi'] ?? '').toString(),
      strTanggalAwal:
          DateTime.tryParse((json['str_tanggal_awal'] ?? '').toString()),
      strTanggalAkhir:
          DateTime.tryParse((json['str_tanggal_akhir'] ?? '').toString()),
      invoice: invoice,
    );
  }

  static int? _toInt(dynamic value) => parseInt(value);

  Map<String, dynamic> toJson() => {
        'ref': ref,
        'auditor_ref': auditorRef,
        'latik_ext': latikExt,
        'status': status,
        'status_verifikasi': statusVerifikasi,
        'catatan_verifikasi': catatanVerifikasi,
        'str_tanggal_awal': strTanggalAwal?.toIso8601String(),
        'str_tanggal_akhir': strTanggalAkhir?.toIso8601String(),
        'paid_ext_invoice': invoice == null ? null : [invoice!.toJson()],
      };
}