import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../bloc/balance/balance_bloc.dart';
import '../../favorites/bloc/favorites_bloc.dart';
import '../bloc/auth_bloc.dart';

class ProfileInfo extends StatelessWidget {
  final User user;

  const ProfileInfo({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
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
              color: Theme.of(context).colorScheme.primary,
            )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.email ?? 'No email',
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
            child: Text(
                'Выход',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary
                )),
          ),
        ],
      ),
    )
    );
  }
}