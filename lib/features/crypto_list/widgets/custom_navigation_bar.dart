import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';

class CustomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const CustomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return NavigationBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            if (index == 1 && authState is! Authenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Войдите, чтобы посмотреть избранное')),
              );
              return;
            }
            onIndexChanged(index);
          },
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home),
                label: 'Главная'
            ),
            NavigationDestination(
                icon: Icon(Icons.star),
                label: 'Избранное'
            ),
            NavigationDestination(
                icon: Icon(Icons.person),
                label: 'Профиль'
            ),
          ],
        );
      },
    );
  }
}