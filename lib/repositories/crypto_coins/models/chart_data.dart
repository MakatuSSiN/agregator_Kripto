import 'package:equatable/equatable.dart';

class ChartSampleData extends Equatable {
  final DateTime x;
  final double open;
  final double close;
  final double low;
  final double high;

  const ChartSampleData({
    required this.x,
    required this.open,
    required this.close,
    required this.low,
    required this.high,
  });

  @override
  List<Object> get props => [x, open, close, low, high];

  // Для удобства отладки можно добавить toString()
  @override
  String toString() {
    return 'ChartSampleData{x: $x, open: $open, close: $close, low: $low, high: $high}';
  }
}