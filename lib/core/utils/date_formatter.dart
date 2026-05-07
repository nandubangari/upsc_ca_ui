import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

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
    print('DEBUG: [DateFormatter] Attempting to parse: "$dateStr"');
    if (dateStr.isEmpty) return DateTime(2000);

    try {
      // 1. Try standard ISO
      final dt = DateTime.parse(dateStr);
      print('DEBUG: [DateFormatter] Successfully parsed as ISO: $dt');
      return dt;
    } catch (_) {}

    try {
      // 2. Try DD MMM YYYY (e.g. 29 APR 2026) manually to avoid locale issues
      final cleaned = dateStr.trim().toUpperCase();
      final parts = cleaned.split(RegExp(r'\s+'));
      if (parts.length == 3) {
        final day = int.tryParse(parts[0].replaceAll(RegExp(r'[^0-9]'), ''));
        final monthStr = parts[1];
        final year = int.tryParse(parts[2]);
        
        const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
        final month = months.indexOf(monthStr) + 1;
        
        if (day != null && year != null && month > 0) {
          final dt = DateTime(year, month, day);
          print('DEBUG: [DateFormatter] Successfully parsed manually: $dt');
          return dt;
        }
      }
    } catch (e) {
      print('DEBUG: [DateFormatter] Manual parse failed: $e');
    }
    
    try {
      // 3. Fallback to DateFormat
      final dt = DateFormat('dd MMM yyyy', 'en_US').parse(dateStr.toUpperCase());
      print('DEBUG: [DateFormatter] Successfully parsed with DateFormat: $dt');
      return dt;
    } catch (e) {
      print('ERROR: [DateFormatter] All parsing attempts failed for: "$dateStr". Last error: $e');
      return DateTime(2000);
    }
  }
}
