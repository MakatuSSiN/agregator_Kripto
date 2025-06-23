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
import '../widgets/widgets.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: Text(
          'Профиль',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
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
              } else if (state is EmailNotVerified) {
                return VerificationSentWidget(
                  email: state.email,
                  canResend: true, // или ваша логика для canResend
                  resendCooldown: 0, // или ваше значение
                  onResendPressed: () {
                    context.read<AuthBloc>().add(ResendVerificationRequested(state.email));
                  },
                  onVerifiedPressed: () async {
                    try {
                      await FirebaseAuth.instance.currentUser?.reload();
                      final user = FirebaseAuth.instance.currentUser;
                      if (user?.emailVerified ?? false) {
                        context.read<AuthBloc>().add(AuthCheckRequested());
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Пожалуйста, подтвердите почту')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка: ${e.toString()}')),
                      );
                    }
                  },
                );
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
            automaticallyImplyLeading: false,
            title: Text(
              user.email ?? 'Профиль',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 22),
            ),
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
              ProfileInfo(user: user),
              PortfolioList(),
            ],
          ),
        ),
      ),
    ),
    );
  }
}