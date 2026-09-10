import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/core/utils/formatters.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() {
    initializeDateFormatting('id_ID');
  });

  group('AppFormatters.formatDate', () {
    test('returns "-" when date is null', () {
      expect(AppFormatters.formatDate(null), '-');
    });

    test('formats date correctly in Indonesian', () {
      final date = DateTime(2024, 1, 15);
      expect(AppFormatters.formatDate(date), '15 Januari 2024');
    });

    test('formats date with single-digit day', () {
      final date = DateTime(2024, 3, 5);
      expect(AppFormatters.formatDate(date), '05 Maret 2024');
    });

    test('formats date in December', () {
      final date = DateTime(2023, 12, 31);
      expect(AppFormatters.formatDate(date), '31 Desember 2023');
    });

    test('formats leap year date', () {
      final date = DateTime(2024, 2, 29);
      expect(AppFormatters.formatDate(date), '29 Februari 2024');
    });
  });

  group('AppFormatters.maskNik', () {
    test('masks a valid 16-digit NIK', () {
      expect(AppFormatters.maskNik('3201234567890001'), '****0001');
    });

    test('fully masks a 4-character NIK (nothing revealed)', () {
      expect(AppFormatters.maskNik('1234'), '****');
    });

    test('returns "****" when NIK has less than 4 characters', () {
      expect(AppFormatters.maskNik('123'), '****');
    });

    test('returns "****" when NIK is empty', () {
      expect(AppFormatters.maskNik(''), '****');
    });

    test('returns "****" when NIK has 3 characters', () {
      expect(AppFormatters.maskNik('abc'), '****');
    });

    test('fully masks a value of exactly 4 characters', () {
      expect(AppFormatters.maskNik('abcd'), '****');
    });

    test('masks a 10-character NIK showing last 4', () {
      expect(AppFormatters.maskNik('1234567890'), '****7890');
    });

    test('reveals only the last 4 at the 5-character boundary', () {
      expect(AppFormatters.maskNik('12345'), '****2345');
    });

    test('never reveals the leading digits of a NIK', () {
      final masked = AppFormatters.maskNik('3201234567890001');
      expect(masked.contains('3201'), isFalse);
    });
  });
}
