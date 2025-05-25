import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agregator_kripto/features/auth/view/auth_screen.dart';
import 'package:agregator_kripto/features/crypto_list/widgets/crypto_coin_tile.dart';
import 'package:agregator_kripto/features/favorites/bloc/favorites_bloc.dart';

import '../../../repositories/crypto_coins/models/crypto_coin.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../crypto_list/view/crypto_list_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
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
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<FavoritesBloc>().add(LoadFavorites());
                },
                child: state.favorites.isEmpty
                    ? const Center(child: Text('No favorites yet'))
                    : ListView.builder(
                  itemCount: state.favorites.length,
                  itemBuilder: (context, index) {
                    final coin = state.favorites[index];
                    return CryptoCoinTile(coin: coin);
                  },
                ),
              );
            }

            return const Center(child: Text('Loading favorites...'));
          },
        );
      },
    );
  }
}

  Widget _buildUnauthenticatedView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Please sign in to view favorites'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AuthScreen()),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  void _toggleFavorite(BuildContext context, CryptoCoin coin) {
    context.read<FavoritesBloc>().add(ToggleFavorite(coin));
  }