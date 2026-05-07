import 'package:intl/intl.dart';

class DateFormatter {
  static String isoToAppDate(String isoDate) {
    try {
      final DateTime dt = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy').format(dt).toUpperCase();
    } catch (e) {
      return isoDate;
    }
  }

  static String formatForVajiram(DateTime date) {
    return DateFormat('yyyy/MM').format(date);
  }

  static String toIso(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static DateTime parseAny(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      try {
        // Handle "31 MAY 2024" or "31 May 2024"
        // Force en_US locale to ensure month names are parsed correctly
        return DateFormat('dd MMM yyyy', 'en_US').parse(dateStr.toUpperCase());
      } catch (_) {
        return DateTime(2000); // Old fallback
      }
    }
  }
}
