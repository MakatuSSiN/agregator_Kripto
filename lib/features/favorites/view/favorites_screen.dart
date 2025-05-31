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
    return BlocListener<AuthBloc, AuthState>(
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
    if (authState is! Authenticated) {
    return _buildUnauthenticatedView(context);
    }

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

    return const Center(child: Text('Loading...'));
          },
        );
      },
    )
    ));
  }

  Widget _buildUnauthenticatedView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Please sign in to view favorites'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(BuildContext context, List<CryptoCoin> favorites) {
    if (favorites.isEmpty) {
      return const Center(child: Text('No favorites yet'));
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