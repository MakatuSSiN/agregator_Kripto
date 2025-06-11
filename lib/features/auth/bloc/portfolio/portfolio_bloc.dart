import 'dart:async';
import 'package:agregator_kripto/repositories/crypto_coins/abstract_coins_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../repositories/crypto_coins/models/portfolio_item.dart';

part 'portfolio_event.dart';
part 'portfolio_state.dart';

/// BLoC для управления портфелем криптовалют пользователя
/// Обрабатывает загрузку, обновление и изменение количества криптовалют в портфеле
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
      emit(PortfolioLoadFailure('Пользователь не авторизован'));
      return;
    }

    emit(PortfolioLoading());

    // Отменяем предыдущую подписку, если она была
    _portfolioSubscription?.cancel();
    // Создаем подписку на коллекцию портфеля пользователя
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
      // Преобразуем документы Firestore в список PortfolioItem
      final portfolioItems = event.docs
          .map((doc) => PortfolioItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      emit(PortfolioLoaded(portfolioItems));
    } catch (e) {
      emit(PortfolioLoadFailure(e.toString()));
    }
  }

  // Уменьшение количества криптовалюты в портфеле (при продаже)
  Future<void> reduceCryptoAmount(String coinSymbol, double amount) async {
    final user = firebaseAuth.currentUser;
    if (user == null) return;

    await firestore.runTransaction((transaction) async {
      final portfolioRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('portfolio')
          .doc(coinSymbol);

      // Получаем текущее количество монет
      final doc = await transaction.get(portfolioRef);
      if (!doc.exists) throw ('Монета не найдена в портфеле');

      final currentAmount = (doc.data()?['amount'] ?? 0).toDouble();
      if (currentAmount < amount) throw ('Недостаточно монет для продажи');

      final newAmount = currentAmount - amount;

      if (newAmount <= 0) {
        // Если продали все монеты, удаляем документ
        transaction.delete(portfolioRef);
      } else {
        // Иначе обновляем количество и дату последней операции
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