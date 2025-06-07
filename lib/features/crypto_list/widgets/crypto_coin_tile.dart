import 'package:agregator_kripto/features/utils/price_formatter.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/crypto_coin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../favorites/bloc/favorites_bloc.dart';

class CryptoCoinTile extends StatelessWidget {
  const CryptoCoinTile({
    super.key,
    required this.coin,
    this.onTap,
  });

  final CryptoCoin coin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, state) {
        final isFavorite = state is FavoritesLoaded
            ? state.favorites.any((c) => c.symbol == coin.symbol)
            : false;
        final theme = Theme.of(context);
        return ListTile(
          leading: SizedBox(
            width: 40,
            height: 40,
            child: Image.network(coin.imageUrl),
          ),
          title: Text(
            coin.name,
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: Text(
            "${formatCryptoPrice(coin.priceInUSD)} \$",
            style: theme.textTheme.labelSmall,
          ),
          trailing: IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.yellow : Colors.grey,
            ),
            onPressed: () {
              final newCoin = coin.copyWith(isFavorite: !isFavorite);
              context.read<FavoritesBloc>().add(ToggleFavorite(newCoin));
            },
          ),
          onTap: () {
            Navigator.of(context).pushNamed(
              '/coin',
              arguments: coin,
            );
          },
        );
      },
    );
  }
}