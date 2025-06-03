import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../favorites/bloc/favorites_bloc.dart';
import '../bloc/auth_bloc.dart';
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
                ? Icon(
                Icons.person,
                size: 50,
            color: Theme.of(context).colorScheme.onPrimary)
                : null,
          ),
          const SizedBox(height: 16),
          Text(user.email ?? 'No email',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                //color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 18,
              ),),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
            onPressed: () {
              context.read<FavoritesBloc>().add(FavoritesUpdated([]));
              context.read<AuthBloc>().add(SignOutRequested());
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)
            ),
          ),
        ],
      ),
    );
  }
}