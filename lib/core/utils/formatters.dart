import 'package:intl/intl.dart';

class AppFormatters {
  static final _idDate = DateFormat('dd MMMM yyyy', 'id_ID');

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return _idDate.format(date);
  }

  static String maskNik(String nik) {
    if (nik.length < 4) return '****';
    return '****${nik.substring(nik.length - 4)}';
  }
}
