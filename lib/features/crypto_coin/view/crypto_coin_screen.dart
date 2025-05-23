import 'package:agregator_kripto/features/crypto_coin/bloc/crypto_chart/crypto_chart_bloc.dart';
import 'package:agregator_kripto/repositories/crypto_coins/crypto_candle_repository.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/crypto_coin.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/crypto_coin_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agregator_kripto/features/crypto_coin/bloc/crypto_coin_details/crypto_coin_details_bloc.dart';
import 'package:agregator_kripto/features/crypto_coin/widgets/widgets.dart';
import 'package:agregator_kripto/features/crypto_coin/widgets/crypto_chart.dart';
import 'package:get_it/get_it.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CryptoCoinScreen extends StatefulWidget {
  const CryptoCoinScreen({super.key});

  @override
  State<CryptoCoinScreen> createState() => _CryptoCoinScreenState();
}

class _CryptoCoinScreenState extends State<CryptoCoinScreen> {
  CryptoCoin? coin;
  late final CryptoCoinDetailsBloc _coinDetailsBloc;
  late final ZoomPanBehavior _zoomPanBehavior;
  late final TrackballBehavior _trackballBehavior;

  @override
  void initState() {
    super.initState();
    _coinDetailsBloc = context.read<CryptoCoinDetailsBloc>();

    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enableDoubleTapZooming: false,
      enablePanning: true,
      zoomMode: ZoomMode.x,
    );

    _trackballBehavior = TrackballBehavior(
      enable: true,
      tooltipSettings: const InteractiveTooltip(
        format: '',
        color: Colors.blueGrey,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    final args = ModalRoute.of(context)?.settings.arguments;
    assert(args != null && args is CryptoCoin);
    coin = args as CryptoCoin;
    _coinDetailsBloc.add(LoadCryptoCoinDetails(currencyCode: coin!.name));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(iconTheme: const IconThemeData(color: Colors.white)),
      body: BlocBuilder<CryptoCoinDetailsBloc, CryptoCoinDetailsState>(
        bloc: _coinDetailsBloc,
        builder: (context, state) {
          if (state is CryptoCoinDetailsLoaded) {
            return BlocProvider(
              create: (context) => CryptoChartBloc(GetIt.I<CryptoCandleRepository>())
                ..add(LoadCryptoChart(coin!.symbol)),
              child: _buildContent(state.coinDetails),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildContent(CryptoCoinDetail coinDetails) {
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
            child: CryptoChart(
              symbol: coin!.symbol,
              zoomPanBehavior: _zoomPanBehavior,
              trackballBehavior: _trackballBehavior,
            ),
          ),
          BaseCard(
            child: Column(
              children: [
                CryptoDataRow(
                  title: 'High 24 Hour',
                  value: '${coinDetails.high24Hour.toStringAsFixed(2)} \$',
                ),
                const SizedBox(height: 6),
                CryptoDataRow(
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

