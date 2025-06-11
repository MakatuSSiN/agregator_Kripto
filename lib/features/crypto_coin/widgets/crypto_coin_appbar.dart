import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agregator_kripto/features/crypto_coin/bloc/crypto_coin_details/crypto_coin_details_bloc.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/crypto_coin.dart';

class CryptoCoinAppBar extends StatelessWidget implements PreferredSizeWidget {
  final CryptoCoin? coin;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final CryptoCoinDetailsBloc coinDetailsBloc;

  const CryptoCoinAppBar({
    super.key,
    required this.coin,
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.coinDetailsBloc,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      actions: [
        IconButton(
          icon: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: isFavorite
                ? Colors.yellow
                : Theme.of(context).appBarTheme.iconTheme?.color,
          ),
          onPressed: onFavoritePressed,
        ),
      ],
      title: BlocBuilder<CryptoCoinDetailsBloc, CryptoCoinDetailsState>(
        bloc: coinDetailsBloc,
        builder: (context, state) {
          if (state is CryptoCoinDetailsLoaded) {
            return Row(
              children: [
                SizedBox(
                  width: 45,
                  height: 45,
                  child: Image.network(
                    state.coinDetails.imageUrl,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.currency_bitcoin),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${state.coinDetails.name}/USD',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onPrimary,
                  ),
                ),
              ],
            );
          }
          return const Text('Загрузка...');
          },
      ),
      centerTitle: true,
    );
  }
}