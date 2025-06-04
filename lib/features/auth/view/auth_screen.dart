import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../repositories/crypto_coins/abstract_coins_repository.dart';
import '../../favorites/bloc/favorites_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/portfolio/portfolio_bloc.dart';
import '../widgets/auth_form.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocListener<AuthBloc, AuthState>(
    listener: (context, state) {
    if (state is Authenticated) {
    // Загружаем избранные при успешной аутентификации
    context.read<FavoritesBloc>().add(LoadFavorites());
    }
    },
    child: BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) {
    if (state is AuthLoading) {
    return const Center(child: CircularProgressIndicator());
    } else if (state is Authenticated) {
    return _UserProfile(user: state.user);
    } else {
    return const AuthForm();}}
    ),
    ));
  }
}

class _UserProfile extends StatelessWidget {
  final User user;

  const _UserProfile({required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PortfolioBloc(
        coinsRepository: GetIt.I<AbstractCoinsRepository>(),
        firestore: FirebaseFirestore.instance,
        firebaseAuth: FirebaseAuth.instance,
      )..add(LoadPortfolio()),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(user.email ?? 'Profile'),
            bottom: const TabBar(
                tabs: [
            Tab(icon: Icon(Icons.person)),
            Tab(icon: Icon(Icons.wallet)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildProfileInfo(context),
            _buildPortfolioList(),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(user.email ?? 'No email',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<FavoritesBloc>().add(FavoritesUpdated([]));
              context.read<AuthBloc>().add(SignOutRequested());
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioList() {
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
                title: Text(item.coinName),
                subtitle: Text('${item.amount.toStringAsFixed(4)} ${item.coinSymbol}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeFromPortfolio(context, item.coinSymbol),
                ),
              );
            },
          );
        }
        return const SizedBox();
      },
    );
  }

  Future<void> _removeFromPortfolio(BuildContext context, String coinSymbol) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('portfolio')
          .doc(coinSymbol)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed $coinSymbol from portfolio')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}