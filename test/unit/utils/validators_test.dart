import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/core/utils/validators.dart';

void main() {
  group('AppValidators.required', () {
    test('returns error when value is null', () {
      expect(AppValidators.required(null, 'Nama'), 'Nama wajib diisi');
    });

    test('returns error when value is empty string', () {
      expect(AppValidators.required('', 'Nama'), 'Nama wajib diisi');
    });

    test('returns error when value is whitespace only', () {
      expect(AppValidators.required('   ', 'Nama'), 'Nama wajib diisi');
    });

    test('returns null when value is valid', () {
      expect(AppValidators.required('John', 'Nama'), isNull);
    });

    test('returns null when value is numeric', () {
      expect(AppValidators.required(123, 'Nomor'), isNull);
    });

    test('field name appears in error message', () {
      expect(AppValidators.required(null, 'Email'), contains('Email'));
      expect(AppValidators.required(null, 'Alamat'), contains('Alamat'));
    });
  });

  group('AppValidators.nib', () {
    test('returns error when value is null', () {
      expect(AppValidators.nib(null), 'NIB wajib diisi');
    });

    test('returns error when value is empty', () {
      expect(AppValidators.nib(''), 'NIB wajib diisi');
    });

    test('returns error when NIB has less than 13 digits', () {
      expect(AppValidators.nib('123456789012'), 'NIB harus terdiri dari 13 digit angka');
    });

    test('returns error when NIB has more than 13 digits', () {
      expect(AppValidators.nib('12345678901234'), 'NIB harus terdiri dari 13 digit angka');
    });

    test('returns error when NIB contains non-digit characters', () {
      expect(AppValidators.nib('123456789012a'), 'NIB harus terdiri dari 13 digit angka');
    });

    test('returns error when NIB contains spaces', () {
      expect(AppValidators.nib('1234 5678 9012'), 'NIB harus terdiri dari 13 digit angka');
    });

    test('returns null for valid 13-digit NIB', () {
      expect(AppValidators.nib('1234567890123'), isNull);
    });

    test('returns null for valid NIB with zeros', () {
      expect(AppValidators.nib('0000000000000'), isNull);
    });
  });

  group('AppValidators.nik', () {
    test('returns error when value is null', () {
      expect(AppValidators.nik(null), 'NIK wajib diisi');
    });

    test('returns error when value is empty', () {
      expect(AppValidators.nik(''), 'NIK wajib diisi');
    });

    test('returns error when NIK has less than 16 digits', () {
      expect(AppValidators.nik('123456789012345'), 'NIK harus terdiri dari 16 digit angka');
    });

    test('returns error when NIK has more than 16 digits', () {
      expect(AppValidators.nik('12345678901234567'), 'NIK harus terdiri dari 16 digit angka');
    });

    test('returns error when NIK contains non-digit characters', () {
      expect(AppValidators.nik('123456789012345a'), 'NIK harus terdiri dari 16 digit angka');
    });

    test('returns null for valid 16-digit NIK', () {
      expect(AppValidators.nik('3201234567890001'), isNull);
    });

    test('returns null for valid NIK with zeros', () {
      expect(AppValidators.nik('0000000000000000'), isNull);
    });
  });

  group('AppValidators.postalCode', () {
    test('returns error when value is null', () {
      expect(AppValidators.postalCode(null), 'Kode pos wajib diisi');
    });

    test('returns error when value is empty', () {
      expect(AppValidators.postalCode(''), 'Kode pos wajib diisi');
    });

    test('returns error when postal code has less than 5 digits', () {
      expect(AppValidators.postalCode('1234'), 'Kode pos harus terdiri dari 5 digit angka');
    });

    test('returns error when postal code has more than 5 digits', () {
      expect(AppValidators.postalCode('123456'), 'Kode pos harus terdiri dari 5 digit angka');
    });

    test('returns error when postal code contains non-digit characters', () {
      expect(AppValidators.postalCode('1234a'), 'Kode pos harus terdiri dari 5 digit angka');
    });

    test('returns null for valid 5-digit postal code', () {
      expect(AppValidators.postalCode('12345'), isNull);
    });

    test('returns null for valid Indonesian postal code', () {
      expect(AppValidators.postalCode('60112'), isNull);
    });
  });
}
