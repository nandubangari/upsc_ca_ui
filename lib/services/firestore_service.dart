import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save or update user profile from Google Auth
  Future<void> saveUser(User user) async {
    final userRef = _db.collection('users').doc(user.uid);

    // Get current data to check if it exists
    final doc = await userRef.get();
    
    final userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'lastSeen': FieldValue.serverTimestamp(),
    };

    // If it's a new user, initialize with comprehensive UPSC defaults
    if (!doc.exists) {
      userData['settings'] = {
        'name': user.displayName ?? '',
        'startDate': DateTime.now().toIso8601String(),
        'repetitionDays': AppConstants.defaultRepetitionDays,
        'availableDays': AppConstants.defaultRepetitionDays,
        'themeColorValue': 0xFFFF6F00, // Default Saffron
        'articleSources': {
          for (var source in AppConstants.defaultArticleSources) source: true
        },
        'quizSources': {
          for (var source in AppConstants.defaultQuizSources) source: true
        },
      };
    }

    await userRef.set(userData, SetOptions(merge: true));
  }

  // Get user profile
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // Example: Save bookmarked article
  Future<void> bookmarkArticle(String uid, String articleUrl, String title) async {
    final bookmarkRef = _db.collection('users').doc(uid).collection('bookmarks').doc();
    
    await bookmarkRef.set({
      'url': articleUrl,
      'title': title,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
