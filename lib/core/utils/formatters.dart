import 'package:intl/intl.dart';

class AppFormatters {
  static final _idDate = DateFormat('dd MMMM yyyy', 'id_ID');
  static final _idShortDate = DateFormat('dd MMM yyyy', 'id_ID');
  static final _idRupiah =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return _idDate.format(date);
  }

  static String formatShortDate(DateTime? date) {
    if (date == null) return '-';
    return _idShortDate.format(date);
  }

  static String formatRupiah(int? amount) {
    if (amount == null) return '-';
    return _idRupiah.format(amount);
  }

  static String maskNik(String nik) {
    if (nik.length <= 8) return '****';
    return '${nik.substring(0, 4)} •••• ${nik.substring(nik.length - 4)}';
  }
}
