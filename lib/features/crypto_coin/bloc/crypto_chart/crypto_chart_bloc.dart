import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/chart_data.dart';
import 'package:agregator_kripto/repositories/crypto_coins/crypto_candle_repository.dart';

part 'crypto_chart_event.dart';
part 'crypto_chart_state.dart';

class CryptoChartBloc extends Bloc<CryptoChartEvent, CryptoChartState> {
  final CryptoCandleRepository repository;

  CryptoChartBloc(this.repository) : super(CryptoChartInitial()) {
    on<LoadCryptoChart>(_loadChart);
  }

  Future<void> _loadChart(
      LoadCryptoChart event,
      Emitter<CryptoChartState> emit,
      ) async {
    emit(CryptoChartLoading());
    try {
      final chartData = await repository.getChartData(event.symbol);
      emit(CryptoChartLoaded(chartData));
    } catch (e) {
      emit(CryptoChartError(e.toString()));
    }
  }
}