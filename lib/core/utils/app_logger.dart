import 'package:flutter/foundation.dart';

class AppLogger {
  static void d(String message) {
    if (kDebugMode) {
      debugPrint('DEBUG: $message');
    }
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint('ERROR: $message');
    if (error != null) debugPrint(error.toString());
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }

  static void i(String message) {
    debugPrint('INFO: $message');
  }
}
