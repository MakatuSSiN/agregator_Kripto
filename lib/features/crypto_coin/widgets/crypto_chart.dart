import 'package:agregator_kripto/features/crypto_coin/bloc/crypto_chart/crypto_chart_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/chart_data.dart';

class CryptoChart extends StatelessWidget {
  final String symbol;
  final ZoomPanBehavior zoomPanBehavior;
  final TrackballBehavior trackballBehavior;

  const CryptoChart({
    super.key,
    required this.symbol,
    required this.zoomPanBehavior,
    required this.trackballBehavior,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CryptoChartBloc, CryptoChartState>(
      builder: (context, state) {
        if (state is CryptoChartLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CryptoChartError) {
          return Center(child: Text(state.message));
        } else if (state is CryptoChartLoaded) {
          final chartData = state.chartData;
          return _buildChart(chartData, context);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildChart(List<ChartSampleData> chartData, BuildContext context) {
    return Container(
      height: 350,
      width: 400,
      child: SfCartesianChart(
        zoomPanBehavior: zoomPanBehavior,
        trackballBehavior: trackballBehavior,
        crosshairBehavior: CrosshairBehavior(
          enable: true,
          hideDelay: 1000,
          lineType: CrosshairLineType.horizontal,

        ),
        series: <CandleSeries<ChartSampleData, DateTime>>[
          CandleSeries<ChartSampleData, DateTime>(
            dataSource: chartData, // Теперь передаем гарантированно не-null список
            xValueMapper: (data, _) => data.x,
            openValueMapper: (data, _) => data.open,
            highValueMapper: (data, _) => data.high,
            lowValueMapper: (data, _) => data.low,
            closeValueMapper: (data, _) => data.close,
            bullColor: Colors.green,
            bearColor: Colors.red,
            enableSolidCandles: true,
            width: 1,
            spacing: 0.1,
            opacity: 1.5,
            borderWidth: 0.9,
            //name: 'val/usd',
          )
        ],
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat.Hm(),
          majorGridLines: const MajorGridLines(
              width: 0.1,
            color: Colors.grey
          ),
          labelStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color, // Цвет текста оси X
          ),
        ),
        primaryYAxis: NumericAxis(
          numberFormat: NumberFormat.currency(
            symbol: '',
            decimalDigits: _getDecimalDigits(_getCurrentPriceRange(chartData)),
          ),//_getDecimalDigits(_getCurrentPriceRange(chartData)),),
          labelStyle: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          majorGridLines: const MajorGridLines(
              width: 0.1,
              color: Colors.grey
          ),
            labelPosition: ChartDataLabelPosition.inside,
            opposedPosition: true,
            maximumLabels: 1,
            edgeLabelPlacement: EdgeLabelPlacement.hide,


        ),
        borderWidth: 0,
        plotAreaBorderWidth: 0,
        margin: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
        // indicators: [
        //   RocIndicator<dynamic, dynamic>(
        //     period: 1,
        //     seriesName: 'val/usd',
        //   ),
        // ],
      ),




    );



  }

  int _getDecimalDigits(double maxPrice) {
    if (maxPrice >= 1000) return 0;
    if (maxPrice >= 10) return 2;
    return 3;
  }

  double _getCurrentPriceRange(List<ChartSampleData> data) {
    if (data.isEmpty) return 0;
    final prices = data.map((d) => d.high).toList();
    return prices.reduce((a, b) => a > b ? a : b);
  }

}