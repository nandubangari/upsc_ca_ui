import 'package:flutter/foundation.dart';

class AppLogger {
  static final Map<String, DateTime> _timers = {};

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

  static void startTimer(String label) {
    if (kDebugMode) {
      _timers[label] = DateTime.now();
    }
  }

  static void endTimer(String label) {
    if (kDebugMode && _timers.containsKey(label)) {
      final startTime = _timers[label]!;
      final duration = DateTime.now().difference(startTime);
      debugPrint('PERF: [$label] took ${duration.inMilliseconds}ms');
      _timers.remove(label);
    }
  }
}
