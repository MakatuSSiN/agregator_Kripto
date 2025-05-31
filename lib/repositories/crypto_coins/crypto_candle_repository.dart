import 'package:agregator_kripto/features/crypto_coin/bloc/crypto_chart/crypto_chart_bloc.dart';
import 'package:dio/dio.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/chart_data.dart';

class CryptoCandleRepository {
  final Dio dio;

  CryptoCandleRepository(this.dio);

  Future<List<ChartSampleData>> getChartData(String symbol, TimeFrame timeFrame) async {
    try {
      String endpoint;
      switch (timeFrame) {
        case TimeFrame.minute:
          endpoint = "histominute";
          break;
        case TimeFrame.hour:
          endpoint = "histohour";
          break;
        case TimeFrame.day:
          endpoint = "histoday";
          break;
      }

      final response = await dio.get(
          "https://min-api.cryptocompare.com/data/v2/$endpoint?fsym=$symbol&tsym=USD&limit=${timeFrame.candleCount}"
      );

      final data = response.data as Map<String, dynamic>;
      final dataRaw = data["Data"] as Map<String, dynamic>;
      final candlesData = dataRaw["Data"] as List<dynamic>;

      return candlesData.map((candle) {
        return ChartSampleData(
          x: DateTime.fromMillisecondsSinceEpoch(candle['time'] * 1000),
          open: candle['open'].toDouble(),
          close: candle['close'].toDouble(),
          low: candle['low'].toDouble(),
          high: candle['high'].toDouble(),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to load chart data: $e');
    }
  }
}