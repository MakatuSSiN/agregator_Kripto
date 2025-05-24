import 'package:dio/dio.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/chart_data.dart';

class CryptoCandleRepository {
  final Dio dio;

  CryptoCandleRepository(this.dio);

  Future<List<ChartSampleData>> getChartData(String symbol) async {
    try {
      final response = await dio.get(
          "https://min-api.cryptocompare.com/data/v2/histominute?fsym=$symbol&tsym=USD&limit=30"
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