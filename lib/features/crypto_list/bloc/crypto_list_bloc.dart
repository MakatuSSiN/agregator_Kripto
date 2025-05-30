import 'dart:async';

import 'package:agregator_kripto/repositories/crypto_coins/crypto_coins.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'crypto_list_event.dart';
part 'crypto_list_state.dart';

class CryptoListBloc extends Bloc<CryptoListEvent, CryptoListState> {
  final AbstractCoinsRepository coinsRepository;
  List<CryptoCoin> _allCoins = [];
  //late Timer _timer;

  CryptoListBloc(this.coinsRepository) : super(CryptoListInitial()) {
    on<LoadCryptoList>(_load);
    on<SearchCryptoList>(_search);
    //_startAutoRefresh();
  }
  // void _startAutoRefresh() {
  //   _timer = Timer.periodic(const Duration(seconds: 100), (timer) {
  //     add(LoadCryptoList());
  //   });
  // }
  Future<void> _load(
      LoadCryptoList event,
      Emitter<CryptoListState> emit,
      ) async {
    try {
      emit(CryptoListLoading());
      _allCoins = await coinsRepository.getCoinsList();
      emit(CryptoListLoaded(
        coinsList: _allCoins,
        filteredCoins: _allCoins,
      ));
    } catch (e) {
      emit(CryptoListLoadingFailure(e));
    }
  }
  void _search(
      SearchCryptoList event,
      Emitter<CryptoListState> emit,
      ) {
    if (state is! CryptoListLoaded) return;

    final currentState = state as CryptoListLoaded;
    final query = event.query.toLowerCase();

    if (query.isEmpty) {
      emit(CryptoListLoaded(
        coinsList: _allCoins,
        filteredCoins: _allCoins,
      ));
      return;
    }

    final filtered = _allCoins.where((coin) {
      return coin.name.toLowerCase().contains(query);
    }).toList();

    emit(CryptoListLoaded(
      coinsList: _allCoins,
      filteredCoins: filtered,
    ));
    @override
    Future<void> close() {
      //_timer.cancel(); // Отменяем таймер при закрытии BLoC
      return super.close();
    }
  }
}