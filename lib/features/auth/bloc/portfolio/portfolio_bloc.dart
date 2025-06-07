import 'dart:async';
import 'package:agregator_kripto/repositories/crypto_coins/abstract_coins_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../repositories/crypto_coins/models/portfolio_item.dart';

part 'portfolio_event.dart';
part 'portfolio_state.dart';

class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  final AbstractCoinsRepository coinsRepository;
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;
  StreamSubscription? _portfolioSubscription;

  PortfolioBloc({
    required this.coinsRepository,
    required this.firestore,
    required this.firebaseAuth,
  }) : super(PortfolioInitial()) {
    on<LoadPortfolio>(_loadPortfolio);
    on<PortfolioUpdated>(_onPortfolioUpdated);
  }

  Future<void> _loadPortfolio(
      LoadPortfolio event,
      Emitter<PortfolioState> emit,
      ) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      emit(PortfolioLoadFailure('User not authenticated'));
      return;
    }

    emit(PortfolioLoading());

    _portfolioSubscription?.cancel();
    _portfolioSubscription = firestore
        .collection('users')
        .doc(user.uid)
        .collection('portfolio')
        .snapshots()
        .listen((snapshot) {
      add(PortfolioUpdated(snapshot.docs));
    });
  }

  void _onPortfolioUpdated(
      PortfolioUpdated event,
      Emitter<PortfolioState> emit,
      ) {
    try {
      final portfolioItems = event.docs
          .map((doc) => PortfolioItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      emit(PortfolioLoaded(portfolioItems));
    } catch (e) {
      emit(PortfolioLoadFailure(e.toString()));
    }
  }

  Future<void> reduceCryptoAmount(String coinSymbol, double amount) async {
    final user = firebaseAuth.currentUser;
    if (user == null) return;

    await firestore.runTransaction((transaction) async {
      final portfolioRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('portfolio')
          .doc(coinSymbol);

      final doc = await transaction.get(portfolioRef);
      if (!doc.exists) throw Exception('Coin not found in portfolio');

      final currentAmount = (doc.data()?['amount'] ?? 0).toDouble();
      if (currentAmount < amount) throw Exception('Not enough coins to sell');

      final newAmount = currentAmount - amount;

      if (newAmount <= 0) {
        // Если продали все монеты, удаляем документ
        transaction.delete(portfolioRef);
      } else {
        transaction.update(portfolioRef, {
          'amount': newAmount,
          'lastPurchaseDate': DateTime.now(),
        });
      }
    });
  }

  @override
  Future<void> close() {
    _portfolioSubscription?.cancel();
    return super.close();
  }
}