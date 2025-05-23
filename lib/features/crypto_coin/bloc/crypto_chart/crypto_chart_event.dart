part of 'crypto_chart_bloc.dart';

abstract class CryptoChartEvent extends Equatable {
  const CryptoChartEvent();

  @override
  List<Object> get props => [];
}

class LoadCryptoChart extends CryptoChartEvent {
  final String symbol;

  const LoadCryptoChart(this.symbol);

  @override
  List<Object> get props => [symbol];
}