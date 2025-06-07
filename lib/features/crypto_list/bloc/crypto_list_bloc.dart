import 'dart:async';

import 'package:agregator_kripto/repositories/crypto_coins/crypto_coins.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'crypto_list_event.dart';
part 'crypto_list_state.dart';

/// BLoC для управления списком криптовалют
/// Обрабатывает загрузку и поиск по списку криптовалют
class CryptoListBloc extends Bloc<CryptoListEvent, CryptoListState> {
  final AbstractCoinsRepository coinsRepository;
  List<CryptoCoin> _allCoins = [];
  CryptoListBloc(this.coinsRepository) : super(CryptoListInitial()) {
    on<LoadCryptoList>(_load);
    on<SearchCryptoList>(_search);
  }

  /// Загрузка списка криптовалют
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

  /// Поиск по списку криптовалют
  void _search(
      SearchCryptoList event,
      Emitter<CryptoListState> emit,
      ) {
    // Поиск возможен только если данные уже загружены
    if (state is! CryptoListLoaded) return;
    final query = event.query.toLowerCase();

    // Если запрос пустой - показываем все криптовалюты
    if (query.isEmpty) {
      emit(CryptoListLoaded(
        coinsList: _allCoins,
        filteredCoins: _allCoins,
      ));
      return;
    }

    // Фильтрация криптовалют по имени
    final filtered = _allCoins.where((coin) {
      return coin.name.toLowerCase().contains(query);
    }).toList();

    emit(CryptoListLoaded(
      coinsList: _allCoins,
      filteredCoins: filtered,
    ));
  }
}