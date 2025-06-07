import 'package:agregator_kripto/features/crypto_coin/widgets/crypto_trade_dialog.dart';
import 'package:agregator_kripto/repositories/crypto_coins/abstract_coins_repository.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/crypto_coin.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/portfolio_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../bloc/portfolio/portfolio_bloc.dart';

class PortfolioList extends StatelessWidget {
  PortfolioList({super.key});

  void _showSellDialog(BuildContext context, PortfolioItem item) async {
    try {
      final coinDetails = await GetIt.I<AbstractCoinsRepository>()
          .getCoinDetails(item.coinName);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          final tempCoin = CryptoCoin(
            symbol: item.coinSymbol,
            name: item.coinName,
            priceInUSD: coinDetails.priceInUSD, // Используем цену из coinDetails
            imageUrl: item.imageUrl, // Используем изображение из portfolio item
          );

          return CryptoTradeDialog(
            coin: tempCoin,
            coinDetails: coinDetails,
            isBuy: false,
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load price data: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortfolioBloc, PortfolioState>(
      builder: (context, state) {
        if (state is PortfolioLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is PortfolioLoadFailure) {
          return Center(child: Text(state.message));
        }
        if (state is PortfolioLoaded) {
          if (state.portfolioItems.isEmpty) {
            return const Center(child: Text('Your portfolio is empty'));
          }

          return ListView.builder(
            itemCount: state.portfolioItems.length,
            itemBuilder: (context, index) {
              final item = state.portfolioItems[index];
              return ListTile(
                leading: SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.network(item.imageUrl),
                ),
                title: Text(
                  item.coinName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                subtitle: Text(
                  item.amount.toStringAsFixed(4),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                  ),
                  onPressed: () => _showSellDialog(context, item),
                  child: Text('Sell',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                )

              );
            },
          );
        }
        return const SizedBox();
      },
    );
  }
}