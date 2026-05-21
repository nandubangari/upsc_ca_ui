import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:upsc_ca_ui/core/config/app_constants.dart';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save or update user core info from Auth
  Future<void> saveUser(User user) async {
    final userRef = _db.collection('users').doc(user.uid);
    final doc = await userRef.get();
    final data = doc.data();

    // Determine createdAt value outside the Map literal for compiler stability
    final createdAt = (doc.exists && data != null && data.containsKey('createdAt'))
        ? data['createdAt']
        : FieldValue.serverTimestamp();

    final now = DateTime.now();
    final Map<String, dynamic> userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'createdAt': createdAt,
      'lastSeen': FieldValue.serverTimestamp(),
    };

    // If it's a new user, initialize with comprehensive UPSC defaults and 3-month free trial
    if (!doc.exists) {
      final trialEnd = now.add(const Duration(days: 90)); // 3 months

      userData['settings'] = {
        'name': user.displayName ?? '',
        'joinedAt': now.toIso8601String(), // Explicitly set join date
        'startDate': now.toIso8601String(),
        'repetitionIntervals': AppConstants.defaultRepetitionDays,
        'themeColorValue': 0xFFFF6F00, // Default Saffron
        'articleSources': {
          for (var source in AppConstants.defaultArticleSources) source: true
        },
        'quizSources': {
          for (var source in AppConstants.defaultQuizSources) source: true
        },
        // Subscription Initial Setup
        'trialStartDate': now.toIso8601String(),
        'trialEndDate': trialEnd.toIso8601String(),
        'isPremium': true, // True during trial
        'manualPremium': false,
        'subscriptionPlan': null,
      };
    }

    await userRef.set(userData, SetOptions(merge: true));
    
    // Cleanup legacy 'settings' if they exist in the root document to keep it clean
    try {
      if (doc.exists && data != null && data.containsKey('settings')) {
        AppLogger.d("Cleaning up legacy settings from root user doc...");
        await userRef.update({
          'settings': FieldValue.delete(),
        });
      }
    } catch (e) {
      // Non-blocking cleanup
      AppLogger.e("Error cleaning up legacy settings", e);
    }
  }

}
