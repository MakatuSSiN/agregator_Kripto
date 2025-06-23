import 'package:cloud_firestore/cloud_firestore.dart';
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
      if (e.code == 'user-not-found') {
        throw AuthException('Пользователь с такой почтой не найден');
      } else if (e.code == 'wrong-password') {
        throw AuthException('Неверный пароль');
      } else if (e.code == 'invalid-email') {
        throw AuthException('Некорректный формат почты');
      } else if (e.code == 'user-disabled') {
        throw AuthException('Аккаунт заблокирован');
      } else {
        throw AuthException('Ошибка входа. Проверьте введенные данные');
      }
    }
  }
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Не удалось отправить письмо для сброса пароля');
    }
  }
  Future<User?> signUp(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .collection('balance')
          .doc('USD')
          .set({'amount': 1000000.0});
      await credential.user?.sendEmailVerification();
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw AuthException('На эту почту уже зарегистрирован аккаунт');
      } else if (e.code == 'weak-password') {
        throw AuthException('Пароль слишком слабый (минимум 6 символов)');
      } else if (e.code == 'invalid-email') {
        throw AuthException('Некорректный формат почты');
      } else {
        throw AuthException('Ошибка регистрации: ${e.message}');
      }
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
          throw AuthException('Пожалуйста, подождите перед отправкой');
        } else {
          throw AuthException(e.message ?? 'Не удалось отправить письмо');
        }
      }
    } else {
      throw AuthException('Нет авторизованного пользователя');
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}