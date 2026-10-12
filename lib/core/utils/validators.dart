class AppValidators {
  static String? required(dynamic value, String field) {
    if (value == null || value.toString().trim().isEmpty) {
      return '$field wajib diisi';
    }
    return null;
  }

  static String? nib(String? value) {
    if (value == null || value.isEmpty) return 'NIB wajib diisi';
    if (!RegExp(r'^\d{13}$').hasMatch(value)) {
      return 'NIB harus terdiri dari 13 digit angka';
    }
    return null;
  }

  static String? nik(String? value) {
    if (value == null || value.isEmpty) return 'NIK wajib diisi';
    if (!RegExp(r'^\d{16}$').hasMatch(value)) {
      return 'NIK harus terdiri dari 16 digit angka';
    }
    return null;
  }

  static String? postalCode(String? value) {
    if (value == null || value.isEmpty) return 'Kode pos wajib diisi';
    if (!RegExp(r'^\d{5}$').hasMatch(value)) {
      return 'Kode pos harus terdiri dari 5 digit angka';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    if (value.length < 8 ||
        !RegExp(r'[a-z]').hasMatch(value) ||
        !RegExp(r'[A-Z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value) ||
        !RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      return 'Password minimal 8 karakter dan memuat huruf kecil, huruf kapital, angka dan simbol';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }
    if (value != password) return 'Konfirmasi password tidak cocok';
    return null;
  }
}
