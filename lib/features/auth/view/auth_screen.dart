import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../repositories/crypto_coins/abstract_coins_repository.dart';
import '../../favorites/bloc/favorites_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/balance/balance_bloc.dart';
import '../bloc/portfolio/portfolio_bloc.dart';
import '../widgets/auth_form.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: Text('Profile', style: Theme.of(context).textTheme.bodyMedium,),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
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
                return const AuthForm();
              }
            }
        ),
      )
    );
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
    child: BlocProvider(
    create: (context) => BalanceBloc(
    firestore: FirebaseFirestore.instance,
    firebaseAuth: FirebaseAuth.instance,
    )..add(SubscribeToBalance()),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: Text(user.email ?? 'Profile', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 22),),
            bottom: TabBar(
              indicatorColor: Theme.of(context).colorScheme.secondary,
              labelColor: Theme.of(context).colorScheme.secondary,
              unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.6),
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
    ),
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            radius: 50,
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? Icon(
                Icons.person,
                size: 50,
            color: Theme.of(context).colorScheme.primary,)
                : null,
          ),
          const SizedBox(height: 16),
          Text(user.email ?? 'No email',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          BlocBuilder<BalanceBloc, BalanceState>(
            builder: (context, state) {
              if (state is BalanceLoaded) {
                return Text(
                  'Баланс: ${state.amount.toStringAsFixed(2)} USD',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                );
              } else if (state is BalanceError) {
                return Text('Ошибка: ${state.message}');
              }
              return const CircularProgressIndicator();
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              context.read<FavoritesBloc>().add(FavoritesUpdated([]));
              context.read<AuthBloc>().add(SignOutRequested());
            },
            child: Text('Sign Out', style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary
            )),
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
                title: Text(
                    item.coinName,
                style: Theme.of(context).textTheme.bodyMedium,),
                subtitle: Text(
                    '${item.amount.toStringAsFixed(4)}', //${item.coinSymbol}
                style: Theme.of(context).textTheme.bodyMedium,),
              );
            },
          );
        }
        return const SizedBox();
      },
    );
  }
}