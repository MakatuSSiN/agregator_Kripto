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
import '../../../repositories/crypto_coins/models/portfolio_item.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/balance/balance_bloc.dart';
import '../../auth/bloc/portfolio/portfolio_bloc.dart';
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
  Future<void> _processPurchase(
      BuildContext context,
      double amount,
      double usdAmount,
      String coinSymbol,
      CryptoCoinDetail coinDetails,
      ) async {
    final balanceBloc = context.read<BalanceBloc>();
    final portfolioBloc = context.read<PortfolioBloc>();
    final user = FirebaseAuth.instance.currentUser!;

    // 1. Проверяем баланс
    final currentBalance = await balanceBloc.getCurrentBalance();
    if (currentBalance < usdAmount) {
      throw Exception('Insufficient funds on balance');
    }

    // 2. Обновляем баланс
    balanceBloc.add(UpdateBalance(usdAmount, true));

    // Ждём завершения обновления баланса
    await balanceBloc.stream.firstWhere((state) =>
    state is BalanceOperationSuccess || state is BalanceError);

    if (balanceBloc.state is BalanceError) {
      throw Exception((balanceBloc.state as BalanceError).message);
    }

    // 3. Добавляем в портфель
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final portfolioRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('portfolio')
          .doc(coinSymbol);

      final doc = await transaction.get(portfolioRef);

      if (doc.exists) {
        final currentAmount = (doc.data()?['amount'] ?? 0).toDouble();
        transaction.update(portfolioRef, {
          'amount': currentAmount + amount,
          'lastPurchaseDate': DateTime.now(),
        });
      } else {
        transaction.set(portfolioRef, {
          'coinSymbol': coinSymbol,
          'coinName': coinDetails.name,
          'amount': amount,
          'firstPurchaseDate': DateTime.now(),
          'lastPurchaseDate': DateTime.now(),
          'imageUrl': coinDetails.imageUrl,
        });
      }
    });

    // Обновляем данные в UI
    portfolioBloc.add(LoadPortfolio());
    balanceBloc.add(LoadBalance());
  }
  Future<void> _processSale(
      BuildContext context,
      double amount,
      double usdAmount,
      String coinSymbol,
      CryptoCoinDetail coinDetails,
      ) async {
    final balanceBloc = context.read<BalanceBloc>();
    final portfolioBloc = context.read<PortfolioBloc>();

    try {
      // 1. Уменьшаем количество криптовалюты в портфеле
      await (portfolioBloc).reduceCryptoAmount(coinSymbol, amount);

      // 2. Обновляем баланс (добавляем USD)
      balanceBloc.add(SellCrypto(usdAmount, false));

      // Ждём завершения обновления баланса
      await balanceBloc.stream.firstWhere((state) =>
      state is BalanceOperationSuccess || state is BalanceError);

      if (balanceBloc.state is BalanceError) {
        throw Exception((balanceBloc.state as BalanceError).message);
      }

      // Обновляем данные в UI
      portfolioBloc.add(LoadPortfolio());
      balanceBloc.add(LoadBalance());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully sold $amount ${coin!.symbol}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

// Добавим метод для показа диалога продажи
  void _showSellDialog(BuildContext context, CryptoCoinDetail coinDetails) {
    context.read<PortfolioBloc>().add(LoadPortfolio());
    final TextEditingController amountController = TextEditingController();
    final TextEditingController usdController = TextEditingController();
    final authState = context.read<AuthBloc>().state;
    bool _isAmountFieldFocused = false;
    bool _isUsdFieldFocused = false;
    bool _isProcessing = false;

    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to sell')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
      return;
    }

    // Функция для обновления полей
    void updateFields({bool fromAmount = true}) {
      final price = coinDetails.priceInUSD;

      if (fromAmount && _isAmountFieldFocused) {
        final amountText = amountController.text;
        if (amountText.isNotEmpty) {
          final amount = double.tryParse(amountText) ?? 0;
          usdController.text = (amount * price).toStringAsFixed(2);
        } else {
          usdController.clear();
        }
      } else if (!fromAmount && _isUsdFieldFocused) {
        final usdText = usdController.text;
        if (usdText.isNotEmpty) {
          final usd = double.tryParse(usdText) ?? 0;
          amountController.text = (usd / price).toStringAsFixed(8);
        } else {
          amountController.clear();
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sell ${coinDetails.name}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 18),
                    controller: amountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount ${coin!.symbol}',
                      labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.secondary
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                      ),
                      border: const OutlineInputBorder(),
                      suffixText: coin!.symbol,
                      suffixStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                    onChanged: (_) => updateFields(fromAmount: true),
                    onTap: () {
                      _isAmountFieldFocused = true;
                      _isUsdFieldFocused = false;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 18),
                    controller: usdController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Total USD',
                      labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.secondary
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                      ),
                      border: OutlineInputBorder(),
                      suffixText: 'USD',
                      suffixStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                    onChanged: (_) => updateFields(fromAmount: false),
                    onTap: () {
                      _isAmountFieldFocused = false;
                      _isUsdFieldFocused = true;
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildQuickAmountButtons(false, coinDetails, amountController, usdController),
                  const SizedBox(height: 10),
                  Text(
                    'Current price: ${formatCryptoPrice(coinDetails.priceInUSD)} \$',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade600,
                          ),
                          onPressed: _isProcessing
                              ? null
                              : () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.primary
                            )
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade900,
                          ),
                          onPressed: _isProcessing
                              ? null
                              : () async {
                            setState(() => _isProcessing = true);
                            try {
                              final amount = double.tryParse(amountController.text);
                              final usdAmount = double.tryParse(usdController.text);

                              if (amount == null || amount <= 0 || usdAmount == null || usdAmount <= 0) {
                                throw Exception('Enter correct amount');
                              }

                              await _processSale(
                                context,
                                amount,
                                usdAmount,
                                coin!.symbol,
                                coinDetails,
                              );
                              Navigator.pop(context);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            } finally {
                              setState(() => _isProcessing = false);
                            }
                          },
                          child: _isProcessing
                              ? const CircularProgressIndicator()
                              : Text(
                              'Sell',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 18,
                                  color: Theme.of(context).colorScheme.primary
                              )
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBuyDialog(BuildContext context, CryptoCoinDetail coinDetails) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController usdController = TextEditingController();
    final authState = context.read<AuthBloc>().state;
    bool _isAmountFieldFocused = false;
    bool _isUsdFieldFocused = false;
    bool _isProcessing = false;

    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to purchase')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
      return;
    }

    // Функция для обновления полей
    void updateFields({bool fromAmount = true}) {
      final price = coinDetails.priceInUSD;

      if (fromAmount && _isAmountFieldFocused) {
        final amountText = amountController.text;
        if (amountText.isNotEmpty) {
          final amount = double.tryParse(amountText) ?? 0;
          usdController.text = (amount * price).toStringAsFixed(2);
        } else {
          usdController.clear();
        }
      } else if (!fromAmount && _isUsdFieldFocused) {
        final usdText = usdController.text;
        if (usdText.isNotEmpty) {
          final usd = double.tryParse(usdText) ?? 0;
          amountController.text = (usd / price).toStringAsFixed(8);
        } else {
          amountController.clear();
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder( // Добавляем StatefulBuilder для обновления состояния
        builder: (context, setState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buy ${coinDetails.name}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 18),
                controller: amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount ${coin!.symbol}',
                  labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.secondary
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                  ),
                  border: const OutlineInputBorder(),
                  suffixText: coin!.symbol,
                  suffixStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
                onChanged: (_) => updateFields(fromAmount: true),
                onTap: () {
                  _isAmountFieldFocused = true;
                  _isUsdFieldFocused = false;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 18),
                controller: usdController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Total USD',
                  labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.secondary
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                  ),
                  border: OutlineInputBorder(),
                  suffixText: 'USD',
                  suffixStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
                onChanged: (_) => updateFields(fromAmount: false),
                onTap: () {
                  _isAmountFieldFocused = false;
                  _isUsdFieldFocused = true;
                },
              ),
              const SizedBox(height: 10),
              _buildQuickAmountButtons(true, coinDetails, amountController, usdController),
              const SizedBox(height: 10),
              Text(
                'Current price: ${formatCryptoPrice(coinDetails.priceInUSD)} \$',
                style: const TextStyle(fontSize: 18),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () => Navigator.pop(context),
                      child: Text(
                          'Cancel',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.primary
                          )
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade900,
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () async {
                        setState(() => _isProcessing = true);
                        try {
                          final amount = double.tryParse(amountController.text);
                          final usdAmount = double.tryParse(usdController.text);

                          if (amount == null || amount <= 0 || usdAmount == null || usdAmount <= 0) {
                            throw Exception('Enter correct amount');
                          }

                          await _processPurchase(
                            context,
                            amount,
                            usdAmount,
                            coin!.symbol,
                            coinDetails,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Successfully purchased $amount ${coin!.symbol}')),
                          );
                          Navigator.pop(context); // Закрываем только после успеха
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                          Navigator.pop(context);
                        } finally {
                          setState(() => _isProcessing = false);
                        }
                      },
                      child: _isProcessing
                          ? const CircularProgressIndicator()
                          : Text(
                          'Buy',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.primary
                          )
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
          ),
        );
      },
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
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
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
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary
                      ),
                    ),
                  ],
                );
              }
              return const Text('Loading...');
            },
          ),
          centerTitle: true,
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
                      onPressed: () => _showBuyDialog(context, coinDetails),
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
                      onPressed: () => _showSellDialog(context, coinDetails),
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

  Widget _buildQuickAmountButtons(bool isBuy, CryptoCoinDetail coinDetails,
      TextEditingController amountController, TextEditingController usdController) {
    return BlocBuilder<PortfolioBloc, PortfolioState>(
        builder: (context, portfolioState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick selection:', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickButton('10%', () => _setQuickAmount(0.1, isBuy, coinDetails, amountController, usdController)),
            _buildQuickButton('25%', () => _setQuickAmount(0.25, isBuy, coinDetails, amountController, usdController)),
            _buildQuickButton('50%', () => _setQuickAmount(0.5, isBuy, coinDetails, amountController, usdController)),
            _buildQuickButton('All', () => _setAllAmount(isBuy, coinDetails, amountController, usdController)),
          ],
        ),
      ],
    );
        },
    );
  }

  Widget _buildQuickButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Future<void> _setAllAmount(bool isBuy, CryptoCoinDetail coinDetails,
      TextEditingController amountController, TextEditingController usdController) async {
    if (!isBuy) {
      // Для продажи - получаем текущий баланс монеты
      final portfolioBloc = context.read<PortfolioBloc>();
      if (portfolioBloc.state is PortfolioLoaded) {
        final portfolioState = portfolioBloc.state as PortfolioLoaded;
        final item = portfolioState.portfolioItems.firstWhere(
              (item) => item.coinSymbol == coin!.symbol,
          orElse: () => PortfolioItem(
            coinSymbol: '',
            coinName: '',
            amount: 0,
            imageUrl: '',
          ),
        );

        if (item.coinSymbol.isNotEmpty) {
          amountController.text = item.amount.toStringAsFixed(8);
          usdController.text = (item.amount * coinDetails.priceInUSD).toStringAsFixed(2);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You do not have a ${coin!.symbol} in portfolio')),
          );
        }
      } else {
        portfolioBloc.add(LoadPortfolio());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading data portfolio...')),
        );
      }
    } else {
      // Для покупки - максимум по текущему балансу USD
      final balanceBloc = context.read<BalanceBloc>();
      final balance = await balanceBloc.getCurrentBalance();
      final maxAmount = balance / coinDetails.priceInUSD;
      amountController.text = maxAmount.toStringAsFixed(8);
      usdController.text = balance.toStringAsFixed(2);
    }
  }

  void _setQuickAmount(
      double percent,
      bool isBuy,
      CryptoCoinDetail coinDetails,
      TextEditingController amountController,
      TextEditingController usdController) {
    if (isBuy) {
      // Для покупки - процент от текущего баланса USD
      final balanceBloc = context.read<BalanceBloc>();
      balanceBloc.getCurrentBalance().then((balance) {
        final amount = (balance * percent) / coinDetails.priceInUSD;
        amountController.text = amount.toStringAsFixed(8);
        usdController.text = (balance * percent).toStringAsFixed(2);
      });
    } else {
      // Для продажи - процент от текущего количества монет
      final portfolioBloc = context.read<PortfolioBloc>();
      if (portfolioBloc.state is PortfolioLoaded) {
        final portfolioState = portfolioBloc.state as PortfolioLoaded;
        final item = portfolioState.portfolioItems.firstWhere(
              (item) => item.coinSymbol == coin!.symbol,
          orElse: () => PortfolioItem(
            coinSymbol: '',
            coinName: '',
            amount: 0,
            imageUrl: '',
          ),
        );

        if (item.coinSymbol.isNotEmpty) {
          final amount = item.amount * percent;
          amountController.text = amount.toStringAsFixed(8);
          usdController.text = (amount * coinDetails.priceInUSD).toStringAsFixed(2);
        }
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'You do not have a ${coin!.symbol} in portfolio'
                )
            ),
          );
        }
      } else {
        // Если портфель еще не загружен, загружаем его
        portfolioBloc.add(LoadPortfolio());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Loading data portfolio...'
              )
          ),
        );
      }
    }
  }
}