import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:upsc_ca_ui/data/services/profile_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Auth state changes stream
  Stream<User?> get user => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null;

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Clear cache just in case
      ProfileService.clearCache();

      // Once signed in, return the UserCredential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      AppLogger.e('Error signing in with Google', e);
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      ProfileService.clearCache();
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      AppLogger.e('Error signing out', e);
    }
  }

  // Current user
  User? get currentUser => _auth.currentUser;
}


