import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/crypto_coin.dart';
import 'package:flutter/cupertino.dart';

class FavoritesRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  FavoritesRepository({
    required this.firestore,
    required this.firebaseAuth,
  });

  Future<List<CryptoCoin>> getFavorites() async {
    final user = firebaseAuth.currentUser;
    if (user == null) throw ('Пользователь не авторизован');

    final snapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();

    return snapshot.docs.map((doc) => CryptoCoin.fromJson(doc.data())).toList();
  }

  Future<void> addFavorite(CryptoCoin coin) async {
    final user = firebaseAuth.currentUser;
    if (user == null) throw ('Пользователь не авторизован');

    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(coin.symbol)
        .set(coin.toJson());
  }

  Future<void> removeFavorite(CryptoCoin coin) async {
    final user = firebaseAuth.currentUser;
    if (user == null) throw ('Пользователь не авторизован');

    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(coin.symbol)
        .delete();
  }
  Stream<List<CryptoCoin>> watchFavorites() {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      debugPrint('FavoritesRepository: No authenticated user');
      return Stream.value([]);
    }

    debugPrint('FavoritesRepository: Starting stream for user ${user.uid}');
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) {
      debugPrint('FavoritesRepository: Received ${snapshot.docs.length} favorites');
      return snapshot.docs.map((doc) {
        final data = doc.data()..['symbol'] = doc.id;
        return CryptoCoin.fromJson(data);
      }).toList();
    })
        .handleError((error) {
      debugPrint('FavoritesRepository: Error: $error');
      return [];
    });
  }
}