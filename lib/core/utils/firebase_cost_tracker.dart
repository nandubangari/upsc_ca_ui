import 'package:upsc_ca_ui/core/utils/app_logger.dart';

class FirebaseCostTracker {
  static int _firestoreReads = 0;
  static int _firestoreWrites = 0;
  static int _rtdbReads = 0; // Each fetch counts as 1 read for now
  static int _rtdbWrites = 0;

  static int get firestoreReads => _firestoreReads;
  static int get firestoreWrites => _firestoreWrites;
  static int get rtdbReads => _rtdbReads;
  static int get rtdbWrites => _rtdbWrites;

  static void recordFirestoreRead([int count = 1]) {
    _firestoreReads += count;
    _log();
  }

  static void recordFirestoreWrite([int count = 1]) {
    _firestoreWrites += count;
    _log();
  }

  static void recordRTDBRead() {
    _rtdbReads += 1;
    _log();
  }

  static void recordRTDBWrite() {
    _rtdbWrites += 1;
    _log();
  }

  static void _log() {
    AppLogger.d("🔥 [Firebase Cost] Firestore: R=$_firestoreReads, W=$_firestoreWrites | RTDB: R=$_rtdbReads, W=$_rtdbWrites");
  }

  static void reset() {
    _firestoreReads = 0;
    _firestoreWrites = 0;
    _rtdbReads = 0;
    _rtdbWrites = 0;
  }
}
