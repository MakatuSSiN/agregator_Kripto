import 'dart:async';

import 'package:agregator_kripto/repositories/crypto_coins/crypto_coins.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'crypto_coin_details_event.dart';
part 'crypto_coin_details_state.dart';

class CryptoCoinDetailsBloc
    extends Bloc<CryptoCoinDetailsEvent, CryptoCoinDetailsState> {
  final AbstractCoinsRepository coinsRepository;
  Timer? _autoRefreshTimer;
  CryptoCoinDetailsBloc(this.coinsRepository)
      : super(const CryptoCoinDetailsState()) {
    on<LoadCryptoCoinDetails>(_load);
    on<StartAutoRefresh>(_startAutoRefresh);
    on<StopAutoRefresh>(_stopAutoRefresh);
  }

  @override
  Future<void> close() {
    _stopAutoRefreshTimer();
    return super.close();
  }

  //final AbstractCoinsRepository coinsRepository;

  Future<void> _load(
      LoadCryptoCoinDetails event,
      Emitter<CryptoCoinDetailsState> emit,
      ) async {
    try {
      if (state is! CryptoCoinDetailsLoaded) {
        emit(const CryptoCoinDetailsLoading());
      }

      final coinDetails =
      await coinsRepository.getCoinDetails(event.currencyCode);

      emit(CryptoCoinDetailsLoaded(coinDetails));
    } catch (e) {
      emit(CryptoCoinDetailsLoadingFailure(e));
    }
  }

  void _startAutoRefresh(
      StartAutoRefresh event,
      Emitter<CryptoCoinDetailsState> emit)
  {
    _stopAutoRefreshTimer();
    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: event.intervalSeconds),
          (_) => add(LoadCryptoCoinDetails(currencyCode: event.currencyCode)),
    );

    // Сразу загружаем данные при старте
    add(LoadCryptoCoinDetails(currencyCode: event.currencyCode));
  }

  void _stopAutoRefresh(
      StopAutoRefresh event,
      Emitter<CryptoCoinDetailsState> emit,
      ) {
    _stopAutoRefreshTimer();
  }

  void _stopAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }
}