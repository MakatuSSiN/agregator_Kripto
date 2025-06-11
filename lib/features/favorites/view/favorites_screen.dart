import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agregator_kripto/features/auth/bloc/auth_bloc.dart';
import 'package:agregator_kripto/features/crypto_list/widgets/crypto_coin_tile.dart';
import 'package:agregator_kripto/features/favorites/bloc/favorites_bloc.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/crypto_coin.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
        appBar: AppBar(
          title: Text('Избранное', style: Theme.of(context).textTheme.bodyMedium,),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: BlocListener<AuthBloc, AuthState>(
        listener: (context, authState) {
          if (authState is Authenticated) {
            // При изменении состояния аутентификации загружаем избранное
            context.read<FavoritesBloc>().add(LoadFavorites());
          }
        },
        child: BlocListener<FavoritesBloc, FavoritesState>(
            listener: (context, state) {
              if (state is FavoritesError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                return BlocBuilder<FavoritesBloc, FavoritesState>(
                  builder: (context, state) {
                    if (state is FavoritesLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is FavoritesError) {
                      return Center(child: Text(state.message));
                    }
                    if (state is FavoritesLoaded) {
                      return _buildFavoritesList(context, state.favorites);
                    }
                    return const Center(child: Text('Загрузка...'));
                    },
                );
                },
            )
        )
        )
    );
  }


  Widget _buildFavoritesList(BuildContext context, List<CryptoCoin> favorites) {
    if (favorites.isEmpty) {
      return const Center(child: Text('Нет избранных криптовалют'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<FavoritesBloc>().add(LoadFavorites());
      },
      child: ListView.builder(
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final coin = favorites[index];
          return CryptoCoinTile(coin: coin);
        },
      ),
    );
  }
}