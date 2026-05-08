import 'package:firebase_auth/firebase_auth.dart';
import 'package:upsc_ca_ui/data/services/auth_service.dart';

class AuthRepository {
  final AuthService _authService = AuthService();

  Stream<User?> get user => _authService.user;
  User? get currentUser => _authService.currentUser;

  Future<UserCredential?> signInWithGoogle() => _authService.signInWithGoogle();
  Future<void> signOut() => _authService.signOut();
}
