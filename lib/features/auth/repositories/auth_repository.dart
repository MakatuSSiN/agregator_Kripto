import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository() : _firebaseAuth = FirebaseAuth.instance;

  Stream<User?> get user => _firebaseAuth.authStateChanges();

  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Sign in failed');
    }
  }

  Future<User?> signUp(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.sendEmailVerification();
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Sign up failed');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> resendVerificationEmail() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        await user.sendEmailVerification();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'too-many-requests') {
          throw AuthException('Please wait before resending');
        } else {
          throw AuthException(e.message ?? 'Failed to send verification email');
        }
      }
    } else {
      throw AuthException('No authenticated user');
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}