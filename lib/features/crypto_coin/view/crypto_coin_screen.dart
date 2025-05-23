import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:agregator_kripto/features/crypto_coin/bloc/crypto_coin_details/crypto_coin_details_bloc.dart';
import 'package:agregator_kripto/features/crypto_coin/widgets/widgets.dart';
import 'package:agregator_kripto/repositories/crypto_coins/crypto_coins.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CryptoCoinScreen extends StatefulWidget {
  const CryptoCoinScreen({super.key});

  @override
  State<CryptoCoinScreen> createState() => _CryptoCoinScreenState();
}

class _CryptoCoinScreenState extends State<CryptoCoinScreen> {
  CryptoCoin? coin;
  late Future<List<ChartSampleData>> _chartDataFuture;
  late final CryptoCoinDetailsBloc _coinDetailsBloc;
  late final CryptoCandleRepo _candleRepo;
  late ZoomPanBehavior _zoomPanBehavior;
  late TrackballBehavior _trackballBehavior;

  @override
  void initState() {
    super.initState();
    _coinDetailsBloc = CryptoCoinDetailsBloc(
      GetIt.I<AbstractCoinsRepository>(),
    );
    _candleRepo = GetIt.I<CryptoCandleRepo>();
    //_chartDataFuture = CryptoCandleRepo().getChartData();
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,     // Включить масштабирование щипком
      enableDoubleTapZooming: false, // Зум двойным тапом
      enablePanning: true,      // Включить скролл/панорамирование
      zoomMode: ZoomMode.x,    // Масштабировать только по оси X
    );

    _trackballBehavior = TrackballBehavior(
      enable: true,
      tooltipSettings: InteractiveTooltip(
        format: '',
        color: Colors.blueGrey,
      ),
    );
  }


  @override
  void didChangeDependencies() {
    final args = ModalRoute.of(context)?.settings.arguments;
    assert(args != null && args is CryptoCoin, 'You must provide String args');
    coin = args as CryptoCoin;
    _coinDetailsBloc.add(LoadCryptoCoinDetails(currencyCode: coin!.name));
    _chartDataFuture = _candleRepo.getChartData(coin!.symbol);
    super.didChangeDependencies();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white)
      ),
      body: BlocBuilder<CryptoCoinDetailsBloc, CryptoCoinDetailsState>(
        bloc: _coinDetailsBloc,
        builder: (context, state) {
          if (state is CryptoCoinDetailsLoaded) {
            final coinDetails = state.coinDetails;
            return Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: Image.network(coinDetails.imageUrl),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    coinDetails.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  BaseCard(
                    child: Center(
                      child: Text(
                        '${coinDetails.priceInUSD.toStringAsFixed(4)} \$',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  BaseCard(
                    child: FutureBuilder<List<ChartSampleData>>(
                    future: _chartDataFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No data available'));
                      }

                      return Container(
                        height: 300,
                        width: 400,
                        child: SfCartesianChart(
                          zoomPanBehavior: _zoomPanBehavior,
                          trackballBehavior: _trackballBehavior,
                          crosshairBehavior: CrosshairBehavior(
                            enable: true,
                            //shouldShowLabel: false,
                            //shouldAlwaysShow: false,
                            //activationMode: ActivationMode.none,
                            hideDelay: 1000,
                            // activationMode: ActivationMode.doubleTap,
                            lineType: CrosshairLineType.horizontal,
                          ),
                          series: <CandleSeries>[

                            CandleSeries<ChartSampleData, DateTime>(
                              dataSource: snapshot.data!,
                              xValueMapper: (ChartSampleData data, _) => data.x,
                              openValueMapper: (ChartSampleData data, _) => data.open,
                              highValueMapper: (ChartSampleData data, _) => data.high,
                              lowValueMapper: (ChartSampleData data, _) => data.low,
                              closeValueMapper: (ChartSampleData data, _) => data.close,
                              //name: 'BTC/USD',
                              bullColor: Colors.green,
                              bearColor: Colors.red,
                              enableSolidCandles: true,
                              width: 1,
                              spacing: 0.3,
                            )
                          ],
                          primaryXAxis: DateTimeAxis(
                            dateFormat: DateFormat.Hm(),
                            majorGridLines: const MajorGridLines(width: 1),
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          primaryYAxis: NumericAxis(
                            numberFormat: NumberFormat.simpleCurrency(decimalDigits: 2),
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                  ),
                  BaseCard(
                    child: Column(
                      children: [
                        _DataRow(
                          title: 'High 24 Hour',
                          value: '${coinDetails.high24Hour.toStringAsFixed(2)} \$',
                        ),
                        const SizedBox(height: 6),
                        _DataRow(
                          title: 'Low 24 Hour',
                          value: '${coinDetails.low24Hour.toStringAsFixed(2)} \$',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 140, child: Text(title)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(value),
        ),
      ],
    );
  }
}

class ChartSampleData {
  ChartSampleData({
    required this.x,
    required this.open,
    required this.close,
    required this.low,
    required this.high
  });

  final DateTime x;
  final num open;
  final num close;
  final num low;
  final num high;

}

class CryptoCandleRepo {
  final Dio dio;
  CryptoCandleRepo(this.dio);
  Future<List<ChartSampleData>> getChartData(String symbol) async {
    try {
      final response = await Dio().get(
          "https://min-api.cryptocompare.com/data/v2/histohour?fsym=$symbol&tsym=USD&limit=24"
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load data');
      }

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
      debugPrint('Error fetching data: $e');
      throw Exception('Failed to parse data');
    }
  }
}