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
  bool _isDataLoaded = false;
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
    if (args != null && (coin == null || coin!.name != args.name)) {
      coin = args;
      _isDataLoaded = false;
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
  void _showBuyDialog(BuildContext context, CryptoCoinDetail coinDetails) {
    final TextEditingController amountController = TextEditingController();
    final authState = context.read<AuthBloc>().state;

    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, войдите в систему для покупки')),
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
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Купить ${coinDetails.name}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Сумма в USD',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Текущая цена: ${formatCryptoPrice(coinDetails.priceInUSD)} \$',
                style: const TextStyle(fontSize: 16),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(0, 50),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(0, 50),
                      ),
                      onPressed: () async {
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Введите корректную сумму')),
                          );
                          return;
                        }

                        try {
                          final user = FirebaseAuth.instance.currentUser!;
                          final portfolioItem = {
                            'coinSymbol': coin!.symbol,
                            'coinName': coinDetails.name,
                            'amountUSD': amount,
                            'priceAtPurchase': coinDetails.priceInUSD,
                            'purchaseDate': DateTime.now(),
                            'imageUrl': coinDetails.imageUrl,
                          };

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('portfolio')
                              .add(portfolioItem);

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Успешно куплено ${coinDetails.name} на сумму $amount \$')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ошибка: $e')),
                          );
                        }
                      },
                      child: const Text('Купить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
        appBar: AppBar(
          actions: [
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.star : Icons.star_border,
                color: _isFavorite ? Colors.yellow : Theme.of(context).appBarTheme.iconTheme?.color,
              ),
              onPressed: () {
                final authState = context.read<AuthBloc>().state;
                if (authState is! Authenticated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please sign in to add favorites')),
                  );
                  // Используем Navigator вместо доступа к состоянию
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
          ],
          //iconTheme: const IconThemeData(color: Colors.white),
          title: BlocBuilder<CryptoCoinDetailsBloc, CryptoCoinDetailsState>(
            bloc: _coinDetailsBloc,
            builder: (context, state) {
              if (state is CryptoCoinDetailsLoaded) {
                return Row(
                  children: [
                    SizedBox(
                      width: 45,
                      height: 45,
                      child: Image.network(
                        state.coinDetails.imageUrl,
                        errorBuilder: (_, __, ___) => const Icon(Icons.currency_bitcoin),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${state.coinDetails.name}/USD',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }
              return const Text('Loading...');
            },
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              // gradient: LinearGradient(
              //   colors: [
              //     Colors.blue.shade900,
              //     Colors.blue.shade700,
              //   ],
              ),
            ),
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
            )]
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
          // SizedBox(
          //   height: 50,
          //   width: 50,
          //   child: Image.network(coinDetails.imageUrl),
          // ),
          // const SizedBox(height: 8),
          // Text(
          //   coinDetails.name,
          //   style: const TextStyle(
          //     fontSize: 26,
          //     fontWeight: FontWeight.w700,
          //   ),
          // ),
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
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () => _showBuyDialog(context, coinDetails),
                child: const Text(
                  'Купить',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
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


