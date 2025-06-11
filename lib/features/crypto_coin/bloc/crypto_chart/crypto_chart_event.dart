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
  minute('1m', 'Минута', 120),
  hour('1h', 'Час', 48),
  day('1d', 'День', 60);

  final String apiValue;
  final String displayName;
  final int candleCount;

  const TimeFrame(this.apiValue, this.displayName, this.candleCount);
}