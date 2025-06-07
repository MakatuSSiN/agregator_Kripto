import 'package:agregator_kripto/features/crypto_coin/bloc/crypto_chart/crypto_chart_bloc.dart';
import 'package:agregator_kripto/features/utils/price_formatter.dart';
import 'package:agregator_kripto/repositories/crypto_coins/abstract_coins_repository.dart';
import 'package:agregator_kripto/repositories/crypto_coins/crypto_candle_repository.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/crypto_coin.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/crypto_coin_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agregator_kripto/features/crypto_coin/bloc/crypto_coin_details/crypto_coin_details_bloc.dart';
import 'package:agregator_kripto/features/crypto_coin/widgets/widgets.dart';
import 'package:agregator_kripto/features/crypto_coin/widgets/crypto_chart.dart';
import 'package:get_it/get_it.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:async';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/view/auth_screen.dart';
import '../../favorites/bloc/favorites_bloc.dart';
import '../widgets/crypto_trade_dialog.dart';

class CryptoCoinScreen extends StatefulWidget {
  const CryptoCoinScreen({super.key});

  @override
  State<CryptoCoinScreen> createState() => _CryptoCoinScreenState();
}

class _CryptoCoinScreenState extends State<CryptoCoinScreen> {
  TimeFrame _selectedTimeFrame = TimeFrame.minute;
  CryptoCoin? coin;
  late final CryptoCoinDetailsBloc _coinDetailsBloc;
  CryptoChartBloc? _chartBloc;
  late final ZoomPanBehavior _zoomPanBehavior;
  late final TrackballBehavior _trackballBehavior;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();
  bool _isFavorite = false;
  StreamSubscription? _favoritesSubscription;
  @override
  void initState() {
    super.initState();
    _selectedTimeFrame = TimeFrame.minute;
    _subscribeToFavorites();
    _coinDetailsBloc = CryptoCoinDetailsBloc(
      GetIt.I<AbstractCoinsRepository>(),
    );

    _chartBloc = CryptoChartBloc(GetIt.I<CryptoCandleRepository>());

    _loadInitialChart();

    _zoomPanBehavior = ZoomPanBehavior(
        enableMouseWheelZooming: true,
        enablePinching: true,
        enableDoubleTapZooming: false,
        enablePanning: true,
        zoomMode: ZoomMode.x,
        maximumZoomLevel: 0.2
    );

    _trackballBehavior = TrackballBehavior(
      enable: true,
      tooltipSettings: const InteractiveTooltip(
        color: Colors.blueGrey,
      ),
    );
  }

  Future<void> _loadInitialChart() async {
    if (coin != null) {
      _chartBloc?.add(LoadCryptoChart(coin!.symbol, timeFrame: _selectedTimeFrame));
    }
  }

  void _subscribeToFavorites() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _favoritesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) {
      if (mounted && coin != null) {
        setState(() {
          _isFavorite = snapshot.docs.any((doc) => doc.id == coin!.symbol);
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    final args = ModalRoute.of(context)?.settings.arguments;
    assert(args != null && args is CryptoCoin);
    coin = args as CryptoCoin;
    _coinDetailsBloc.add(StartAutoRefresh(currencyCode: coin!.name));
    _coinDetailsBloc.add(LoadCryptoCoinDetails(currencyCode: coin!.name));
    _chartBloc?.add(LoadCryptoChart(coin!.symbol));
    if (coin == null || coin!.name != args.name) {
      coin = args;
      _coinDetailsBloc.add(LoadCryptoCoinDetails(currencyCode: coin!.name));
      _chartBloc?.add(LoadCryptoChart(coin!.symbol, timeFrame: _selectedTimeFrame));
    }
    super.didChangeDependencies();
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _coinDetailsBloc.add(const StopAutoRefresh());
    _favoritesSubscription?.cancel();
    _coinDetailsBloc.close();
    _chartBloc?.close();
    super.dispose();
  }

  void _checkFavoriteStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(coin?.symbol)
        .get();

    if (mounted) {
      setState(() {
        _isFavorite = doc.exists;
      });
    }
  }
// Добавим метод для показа диалога продажи
  void _showTradeDialog(BuildContext context, CryptoCoinDetail coinDetails, bool isBuy) {
    final authState = context.read<AuthBloc>().state;

    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login to ${isBuy ? 'purchase' : 'sell'}')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CryptoTradeDialog(
        coin: coin!,
        coinDetails: coinDetails,
        isBuy: isBuy,
      ),
    );
  }
  Future<void> _refreshData() async {
    if (coin != null) {
      _coinDetailsBloc.add(LoadCryptoCoinDetails(currencyCode: coin!.name));
      _chartBloc?.add(LoadCryptoChart(coin!.symbol, timeFrame: _selectedTimeFrame));
      //context.read<CryptoChartBloc>().add(LoadCryptoChart(coin!.symbol));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        appBar: CryptoCoinAppBar(
          coin: coin,
          coinDetailsBloc: _coinDetailsBloc,
          isFavorite: _isFavorite,
          onFavoritePressed: () {
            final authState = context.read<AuthBloc>().state;
            if (authState is! Authenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please sign in to add favorites')),
              );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
              return;
            }

            if (coin != null) {
              context.read<FavoritesBloc>().add(ToggleFavorite(coin!));
              setState(() {
                _isFavorite = !_isFavorite;
              });
            }
          },
        ),


        //),
    body: RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _refreshData,
      child: BlocBuilder<CryptoCoinDetailsBloc, CryptoCoinDetailsState>(
        bloc: _coinDetailsBloc,
        builder: (context, state) {
          if (state is CryptoCoinDetailsLoaded) {
            return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                    children: [
                      if (_chartBloc != null)
                        BlocProvider.value(
                          value: _chartBloc!,
                          // create: (context) => CryptoChartBloc(GetIt.I<CryptoCandleRepository>())
                          //   ..add(LoadCryptoChart(coin!.symbol)),
                          child: _buildContent(state.coinDetails),
                        )
                    ]
                )
            );

          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    ));
  }

  Widget _buildContent(CryptoCoinDetail coinDetails) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 350,
            child: SegmentedButton<TimeFrame>(
              segments: TimeFrame.values.map((timeFrame) {
                return ButtonSegment<TimeFrame>(
                  value: timeFrame,
                  label: Text(timeFrame.displayName),
                );
              }).toList(),
              selected: {_selectedTimeFrame},
              onSelectionChanged: (Set<TimeFrame> newSelection) {
                setState(() {
                  _selectedTimeFrame = newSelection.first;
                  // Перезагружаем график с новым таймфреймом
                  _chartBloc?.add(LoadCryptoChart(coin!.symbol, timeFrame: _selectedTimeFrame));
                });
              },
            ),
          ),

          const SizedBox(height: 8),

          BaseCard(
            child: CryptoChart(
              symbol: coin!.symbol,
              zoomPanBehavior: _zoomPanBehavior,
              trackballBehavior: _trackballBehavior,
            ),
          ),
          BaseCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${formatCryptoPrice(coinDetails.priceInUSD)} \$',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: coinDetails.priceChangePercentage >= 0
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${coinDetails.priceChangePercentage >= 0 ? '+' : ''}${coinDetails.priceChangePercentage.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: coinDetails.priceChangePercentage >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          BaseCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade900,
                      ),
                      onPressed: () => _showTradeDialog(context, coinDetails, true),
                      child: Text(
                        'Buy',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900,
                      ),
                      onPressed: () => _showTradeDialog(context, coinDetails, false),
                      child: Text(
                        'Sell',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          BaseCard(
            child: Column(
              children: [
                CryptoDataRow(
                  title: 'High 24 Hour',
                  value: '${formatCryptoPrice(coinDetails.high24Hour)} \$',
                ),
                const SizedBox(height: 6),
                CryptoDataRow(
                  title: 'Low 24 Hour',
                  value: '${formatCryptoPrice(coinDetails.low24Hour)} \$',
                ),
                const SizedBox(height: 6),

              ],
            ),
          ),
        ],
      ),
    );
  }
}