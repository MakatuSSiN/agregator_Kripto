import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/crypto_coin.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/crypto_coin_details.dart';
import 'package:agregator_kripto/features/auth/bloc/balance/balance_bloc.dart';
import 'package:agregator_kripto/features/auth/bloc/portfolio/portfolio_bloc.dart';
import 'package:agregator_kripto/features/auth/bloc/auth_bloc.dart';
import 'package:agregator_kripto/features/auth/view/auth_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repositories/crypto_coins/models/portfolio_item.dart';
import '../../utils/price_formatter.dart';

class CryptoTradeDialog extends StatefulWidget {
  final CryptoCoin coin;
  final CryptoCoinDetail coinDetails;
  final bool isBuy;

  const CryptoTradeDialog({
    super.key,
    required this.coin,
    required this.coinDetails,
    required this.isBuy,
  });

  @override
  State<CryptoTradeDialog> createState() => _CryptoTradeDialogState();
}

class _CryptoTradeDialogState extends State<CryptoTradeDialog> {
  late final TextEditingController amountController;
  late final TextEditingController usdController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    usdController = TextEditingController();
  }

  @override
  void dispose() {
    amountController.dispose();
    usdController.dispose();
    super.dispose();
  }

  void _updateFields(String value, bool isAmountField) {
    final price = widget.coinDetails.priceInUSD;
    if (value.isEmpty) {
      if (isAmountField) {
        usdController.text = '';
      } else {
        amountController.text = '';
      }
      return;
    }
    final parsedValue = double.tryParse(value) ?? 0;

    if (isAmountField) {
      usdController.text = (parsedValue * price).toStringAsFixed(2);
    } else {
      amountController.text = (parsedValue / price).toStringAsFixed(8);
    }
  }

  Future<void> _processTrade() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final amount = double.tryParse(amountController.text);
      final usdAmount = double.tryParse(usdController.text);

      if (amount == null || amount <= 0 || usdAmount == null || usdAmount <= 0) {
        throw Exception('Enter correct amount');
      }

      if (widget.isBuy) {
        await _processPurchase(amount, usdAmount);
      } else {
        await _processSale(amount, usdAmount);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _processPurchase(double amount, double usdAmount) async {
    final balanceBloc = context.read<BalanceBloc>();
    final portfolioBloc = context.read<PortfolioBloc>();
    final user = FirebaseAuth.instance.currentUser!;

    // 1. Check balance
    final currentBalance = await balanceBloc.getCurrentBalance();
    if (currentBalance < usdAmount) {
      throw Exception('Insufficient funds on balance');
    }

    // 2. Update balance
    balanceBloc.add(UpdateBalance(usdAmount, true));

    // Wait for balance update
    await balanceBloc.stream.firstWhere((state) =>
    state is BalanceOperationSuccess || state is BalanceError);

    if (balanceBloc.state is BalanceError) {
      throw Exception((balanceBloc.state as BalanceError).message);
    }

    // 3. Add to portfolio
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final portfolioRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('portfolio')
          .doc(widget.coin.symbol);

      final doc = await transaction.get(portfolioRef);

      if (doc.exists) {
        final currentAmount = (doc.data()?['amount'] ?? 0).toDouble();
        transaction.update(portfolioRef, {
          'amount': currentAmount + amount,
          'lastPurchaseDate': DateTime.now(),
        });
      } else {
        transaction.set(portfolioRef, {
          'coinSymbol': widget.coin.symbol,
          'coinName': widget.coinDetails.name,
          'amount': amount,
          'firstPurchaseDate': DateTime.now(),
          'lastPurchaseDate': DateTime.now(),
          'imageUrl': widget.coinDetails.imageUrl,
        });
      }
    });

    // Update UI
    portfolioBloc.add(LoadPortfolio());
    balanceBloc.add(LoadBalance());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully purchased $amount ${widget.coin.symbol}')),
    );
  }

  Future<void> _processSale(double amount, double usdAmount) async {
    final balanceBloc = context.read<BalanceBloc>();
    final portfolioBloc = context.read<PortfolioBloc>();

    try {
      // 1. Reduce crypto amount in portfolio
      await portfolioBloc.reduceCryptoAmount(widget.coin.symbol, amount);

      // 2. Update balance (add USD)
      balanceBloc.add(SellCrypto(usdAmount, false));

      // Wait for balance update
      await balanceBloc.stream.firstWhere((state) =>
      state is BalanceOperationSuccess || state is BalanceError);

      if (balanceBloc.state is BalanceError) {
        throw Exception((balanceBloc.state as BalanceError).message);
      }

      // Update UI
      portfolioBloc.add(LoadPortfolio());
      balanceBloc.add(LoadBalance());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully sold $amount ${widget.coin.symbol}')),
      );
    } catch (e) {
      rethrow;
    }
  }

  void _setQuickAmount(double percent) {
    if (widget.isBuy) {
      // For buy - percent of current USD balance
      final balanceBloc = context.read<BalanceBloc>();
      balanceBloc.getCurrentBalance().then((balance) {
        final amount = (balance * percent) / widget.coinDetails.priceInUSD;
        amountController.text = amount.toStringAsFixed(8);
        usdController.text = (balance * percent).toStringAsFixed(2);
      });
    } else {
      // For sell - percent of current coin amount
      final portfolioBloc = context.read<PortfolioBloc>();
      if (portfolioBloc.state is PortfolioLoaded) {
        final portfolioState = portfolioBloc.state as PortfolioLoaded;
        final item = portfolioState.portfolioItems.firstWhere(
              (item) => item.coinSymbol == widget.coin.symbol,
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
          usdController.text = (amount * widget.coinDetails.priceInUSD).toStringAsFixed(2);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You do not have ${widget.coin.symbol} in portfolio')),
          );
        }
      } else {
        portfolioBloc.add(LoadPortfolio());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading portfolio data...')),
        );
      }
    }
  }

  void _setAllAmount() async {
    if (!widget.isBuy) {
      // For sell - get current coin balance
      final portfolioBloc = context.read<PortfolioBloc>();
      if (portfolioBloc.state is PortfolioLoaded) {
        final portfolioState = portfolioBloc.state as PortfolioLoaded;
        final item = portfolioState.portfolioItems.firstWhere(
              (item) => item.coinSymbol == widget.coin.symbol,
          orElse: () => PortfolioItem(
            coinSymbol: '',
            coinName: '',
            amount: 0,
            imageUrl: '',
          ),
        );

        if (item.coinSymbol.isNotEmpty) {
          amountController.text = item.amount.toStringAsFixed(8);
          usdController.text = (item.amount * widget.coinDetails.priceInUSD).toStringAsFixed(2);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You do not have ${widget.coin.symbol} in portfolio')),
          );
        }
      } else {
        portfolioBloc.add(LoadPortfolio());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading portfolio data...')),
        );
      }
    } else {
      // For buy - max based on current USD balance
      final balanceBloc = context.read<BalanceBloc>();
      final balance = await balanceBloc.getCurrentBalance();
      final maxAmount = balance / widget.coinDetails.priceInUSD;
      amountController.text = maxAmount.toStringAsFixed(8);
      usdController.text = balance.toStringAsFixed(2);
    }
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.516,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.isBuy ? 'Buy' : 'Sell'} ${widget.coinDetails.name}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 18),
              controller: amountController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}')),
              ],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount ${widget.coin.symbol}',
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
                suffixText: widget.coin.symbol,
                suffixStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              onChanged: (value) => _updateFields(value, true),
            ),
            const SizedBox(height: 16),
            TextField(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 18),
              controller: usdController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
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
                border: const OutlineInputBorder(),
                suffixText: 'USD',
                suffixStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              onChanged: (value) => _updateFields(value, false),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick selection:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickButton('10%', () => _setQuickAmount(0.1)),
                    _buildQuickButton('25%', () => _setQuickAmount(0.25)),
                    _buildQuickButton('50%', () => _setQuickAmount(0.5)),
                    _buildQuickButton('All', _setAllAmount),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Current price: ${formatCryptoPrice(widget.coinDetails.priceInUSD)} \$',
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
                      backgroundColor: widget.isBuy ? Colors.green.shade900 : Colors.red.shade900,
                    ),
                    onPressed: _isProcessing
                        ? null
                        : _processTrade,
                    child: _isProcessing
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                        widget.isBuy ? 'Buy' : 'Sell',
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
    );
  }
}