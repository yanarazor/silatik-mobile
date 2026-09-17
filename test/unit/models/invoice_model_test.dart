import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/data/models/invoice_model.dart';

void main() {
  group('InvoiceModel.fromJson', () {
    test('parses the three sample invoices with correct enum mapping', () {
      // Straight from the listinvoices example response.
      final rows = [
        {
          'ref': '97904bfc-20aa-4b72-a029-650ee127b27f',
          'nama_latik': 'PT MAJU MAKMUR',
          'tagihan_total': 5000000,
          'created_at': '2025-06-18T03:25:03.000000Z',
          'updated_at': '2025-06-20T09:00:00.000000Z',
          'status': 2,
          'kode': 'L12025061855671',
          'invoice_type': 1,
        },
        {
          'ref': '1ba591a2-de07-4d73-9920-210007f238d6',
          'nama_latik': 'PT MAJU MAKMUR',
          'kode_tagihan': '820250709995879',
          'tagihan_total': 1000000,
          'created_at': '2025-06-18T03:39:14.000000Z',
          'status': 1,
          'kode': 'A32025061885182',
          'invoice_type': 5,
        },
        {
          'ref': '9577c621-a206-41f0-aaf5-c378c30a1fca',
          'nama_latik': 'PT MAJU MAKMUR',
          'tagihan_total': 3750000,
          'created_at': '2025-08-13T03:18:15.000000Z',
          'status': 2,
          'kode': 'L22025081376150',
          'invoice_type': 2,
        },
      ];

      final invoices = rows.map(InvoiceModel.fromJson).toList();

      expect(invoices[0].kode, 'L12025061855671');
      expect(invoices[0].tagihanTotal, 5000000);
      expect(invoices[0].status, InvoiceStatus.lunas);
      expect(invoices[0].type, InvoiceType.registrasiLatik);
      expect(invoices[0].createdAt, isNotNull);
      expect(invoices[0].updatedAt, DateTime.utc(2025, 6, 20, 9));
      // Row without updated_at leaves it null (card falls back to createdAt).
      expect(invoices[1].updatedAt, isNull);

      expect(invoices[1].status, InvoiceStatus.terhutang);
      expect(invoices[1].type, InvoiceType.penambahanAuditor);
      expect(invoices[1].kodeTagihan, '820250709995879');

      // Rows without kode_tagihan degrade to empty string.
      expect(invoices[0].kodeTagihan, '');

      expect(invoices[2].status, InvoiceStatus.lunas);
      expect(invoices[2].type, InvoiceType.perpanjanganLatik);
    });

    test('maps status code 99 to kadaluarsa and unknown to lainnya', () {
      expect(InvoiceModel.statusFromCode(99), InvoiceStatus.kadaluarsa);
      expect(InvoiceModel.statusFromCode(null), InvoiceStatus.lainnya);
      expect(InvoiceModel.statusFromCode(7), InvoiceStatus.lainnya);
    });

    test('unknown/null invoice_type falls back to Registrasi LATIK', () {
      expect(InvoiceModel.typeFromCode(null), InvoiceType.registrasiLatik);
      expect(InvoiceModel.typeFromCode(99), InvoiceType.registrasiLatik);
      expect(InvoiceModel.typeFromCode(3), InvoiceType.registrasiAuditor);
    });

    test('null kode/nama_latik degrade to dash, missing amounts to 0', () {
      final model = InvoiceModel.fromJson({
        'ref': 'r',
        'kode': null,
        'nama_latik': null,
      });
      expect(model.kode, '-');
      expect(model.namaLatik, '-');
      expect(model.tagihanTotal, 0);
      expect(model.createdAt, isNull);
    });

    test('filter query codes match the API contract', () {
      expect(InvoiceStatus.terhutang.code, 1);
      expect(InvoiceStatus.lunas.code, 2);
      expect(InvoiceStatus.kadaluarsa.code, 99);
      expect(InvoiceType.perpanjanganAuditor.code, 4);
      expect(InvoiceType.penambahanAuditor.code, 5);
    });
  });
}
