import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/data/models/notifikasi_model.dart';

void main() {
  group('NotifikasiModel.fromJson', () {
    test('parses complete JSON with primary keys', () {
      final json = {
        'ref': 'NOTIF-001',
        'judul': 'Verifikasi Berhasil',
        'isi': 'LATIK Anda telah diverifikasi',
        'kategori': 'Verifikasi',
        'waktu': '2024-06-15T10:30:00.000',
        'is_read': true,
        'data': {
          'action': 'https://example.com/action',
        },
      };

      final model = NotifikasiModel.fromJson(json);

      expect(model.id, 'NOTIF-001');
      expect(model.judul, 'Verifikasi Berhasil');
      expect(model.isi, 'LATIK Anda telah diverifikasi');
      expect(model.kategori, 'Verifikasi');
      expect(model.waktu, DateTime(2024, 6, 15, 10, 30));
      expect(model.isRead, isTrue);
      expect(model.actionUrl, 'https://example.com/action');
    });

    test('falls back to alternative keys', () {
      final json = {
        'id': 'NOTIF-002',
        'title': 'Pemberitahuan',
        'body': 'Ada pembaruan sistem',
        'type': 'Info',
        'created_at': '2024-01-01T00:00:00.000',
        'read_at': '2024-01-01T01:00:00.000',
      };

      final model = NotifikasiModel.fromJson(json);

      expect(model.id, 'NOTIF-002');
      expect(model.judul, 'Pemberitahuan');
      expect(model.isi, 'Ada pembaruan sistem');
      expect(model.kategori, 'Info');
      expect(model.isRead, isTrue);
    });

    test('reads from nested data payload', () {
      final json = {
        'id': 'NOTIF-003',
        'data': {
          'title': 'Nested Title',
          'message': 'Nested message body',
          'type': 'Alert',
          'action_url': 'https://example.com/nested',
        },
      };

      final model = NotifikasiModel.fromJson(json);

      expect(model.judul, 'Nested Title');
      expect(model.isi, 'Nested message body');
      expect(model.kategori, 'Alert');
      expect(model.actionUrl, 'https://example.com/nested');
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{};
      final model = NotifikasiModel.fromJson(json);

      expect(model.id, '');
      expect(model.judul, 'Notifikasi');
      expect(model.isi, '');
      expect(model.kategori, 'Info');
      expect(model.isRead, isFalse);
      expect(model.actionUrl, isNull);
    });

    test('isRead is true when status_baca is 1', () {
      final json = {
        'id': '1',
        'status_baca': 1,
        'waktu': '2024-01-01T00:00:00.000',
      };
      final model = NotifikasiModel.fromJson(json);
      expect(model.isRead, isTrue);
    });

    test('isRead is false when no read indicators present', () {
      final json = {
        'id': '1',
        'waktu': '2024-01-01T00:00:00.000',
      };
      final model = NotifikasiModel.fromJson(json);
      expect(model.isRead, isFalse);
    });

    test('uses updated_at as fallback for waktu', () {
      final json = {
        'id': '1',
        'updated_at': '2024-03-15T12:00:00.000',
      };
      final model = NotifikasiModel.fromJson(json);
      expect(model.waktu, DateTime(2024, 3, 15, 12, 0));
    });

    test('uses tanggal as fallback for waktu', () {
      final json = {
        'id': '1',
        'tanggal': '2024-05-20T08:00:00.000',
      };
      final model = NotifikasiModel.fromJson(json);
      expect(model.waktu, DateTime(2024, 5, 20, 8, 0));
    });

    test('defaults waktu to now when no time field present', () {
      final before = DateTime.now();
      final json = {'id': '1'};
      final model = NotifikasiModel.fromJson(json);
      final after = DateTime.now();

      expect(model.waktu.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(
          model.waktu.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('defaults waktu to now when time string is unparseable', () {
      final json = {
        'id': '1',
        'waktu': 'not-a-date',
      };
      final model = NotifikasiModel.fromJson(json);
      expect(model.waktu, isA<DateTime>());
    });
  });

  group('NotifikasiModel.toJson', () {
    test('serializes all fields', () {
      final model = NotifikasiModel(
        id: 'NOTIF-001',
        judul: 'Test',
        isi: 'Body',
        kategori: 'Info',
        waktu: DateTime(2024, 6, 15, 10, 30),
        isRead: true,
        actionUrl: 'https://example.com',
      );

      final json = model.toJson();
      expect(json['id'], 'NOTIF-001');
      expect(json['judul'], 'Test');
      expect(json['isi'], 'Body');
      expect(json['kategori'], 'Info');
      expect(json['waktu'], '2024-06-15T10:30:00.000');
      expect(json['is_read'], isTrue);
      expect(json['action_url'], 'https://example.com');
    });

    test('action_url is null when not set', () {
      final model = NotifikasiModel(
        id: '1',
        judul: 'Test',
        isi: '',
        kategori: 'Info',
        waktu: DateTime(2024, 1, 1),
      );
      expect(model.toJson()['action_url'], isNull);
    });
  });
}
