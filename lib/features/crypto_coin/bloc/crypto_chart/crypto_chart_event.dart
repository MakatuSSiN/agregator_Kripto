part of 'crypto_chart_bloc.dart';

abstract class CryptoChartEvent extends Equatable {
  const CryptoChartEvent();

  @override
  List<Object> get props => [];
}

class LoadCryptoChart extends CryptoChartEvent {
  final String symbol;
  final TimeFrame timeFrame;

  const LoadCryptoChart(this.symbol, {this.timeFrame = TimeFrame.minute});

  @override
  List<Object> get props => [symbol, timeFrame];
}

enum TimeFrame {
  minute('1m', '1Minute', 120),
  hour('1h', '1Hour', 48),
  day('1d', '1Day', 60);

  final String apiValue;
  final String displayName;
  final int candleCount;

  const TimeFrame(this.apiValue, this.displayName, this.candleCount);
}