import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'balance_event.dart';
part 'balance_state.dart';

class BalanceBloc extends Bloc<BalanceEvent, BalanceState> {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;
  StreamSubscription? _balanceSubscription;

  BalanceBloc({
    required this.firestore,
    required this.firebaseAuth,
  }) : super(BalanceInitial()) {
    on<LoadBalance>(_loadBalance);
    on<UpdateBalance>(_updateBalance);
    on<SubscribeToBalance>(_subscribeToBalance);
  }
  Future<void> _subscribeToBalance(
      SubscribeToBalance event,
      Emitter<BalanceState> emit,
      ) async {
    await _balanceSubscription?.cancel();
    final user = firebaseAuth.currentUser;
    if (user == null) return;

    _balanceSubscription = firestore
        .collection('users')
        .doc(user.uid)
        .collection('balance')
        .doc('USD')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        add(LoadBalance());
      }
    });
  }
  Future<void> _loadBalance(
      LoadBalance event,
      Emitter<BalanceState> emit,
      ) async {
    emit(BalanceLoading());
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final doc = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('balance')
          .doc('USD')
          .get();

      if (!doc.exists) throw Exception('Balance not found');

      emit(BalanceLoaded(doc.data()!['amount']));
    } catch (e) {
      emit(BalanceError(e.toString()));
    }
  }

  Future<void> _updateBalance(
      UpdateBalance event,
      Emitter<BalanceState> emit,
      ) async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final balanceRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('balance')
          .doc('USD');

      await firestore.runTransaction((transaction) async {
        final doc = await transaction.get(balanceRef);
        final currentBalance = (doc.data()?['amount'] ?? 0).toDouble();

        final newBalance = event.isSpending
            ? currentBalance - event.amount
            : currentBalance + event.amount;

        if (event.isSpending && newBalance < 0) {
          throw Exception('Insufficient funds');
        }

        transaction.update(balanceRef, {'amount': newBalance});
        return newBalance;
      });

      final doc = await balanceRef.get();
      emit(BalanceOperationSuccess(doc.data()!['amount']));
    } catch (e) {
      emit(BalanceError(e.toString()));
      rethrow;
    }
  }
  Future<double> getCurrentBalance() async {
    final user = firebaseAuth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final doc = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('balance')
        .doc('USD')
        .get();

    if (!doc.exists) throw Exception('Balance not found');
    return (doc.data()?['amount'] ?? 0).toDouble();
  }
}