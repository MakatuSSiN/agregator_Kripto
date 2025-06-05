import 'package:agregator_kripto/features/crypto_list/widgets/crypto_coin_tile.dart';
import 'package:agregator_kripto/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/view/auth_screen.dart';
import '../../favorites/bloc/favorites_bloc.dart';
import '../../favorites/view/favorites_screen.dart';
import '../bloc/crypto_list_bloc.dart';

class CryptoListScreen extends StatefulWidget {
  const CryptoListScreen({super.key, required this.title});
  final String title;

  @override
  CryptoListScreenState createState() => CryptoListScreenState();
}

class CryptoListScreenState extends State<CryptoListScreen> {
  int _currentPageIndex = 0;
  final _searchController = TextEditingController();
  late final CryptoListBloc _cryptoListBloc;
  void changePage(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }
  final List<Widget> _pages = [
    const _CryptoListContent(),
    const FavoritesScreen(),
    const AuthScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _cryptoListBloc = context.read<CryptoListBloc>();
    _cryptoListBloc.add(LoadCryptoList());
// Слушаем изменения аутентификации
    context.read<AuthBloc>().stream.listen((authState) {
      if (authState is Unauthenticated) {
        context.read<FavoritesBloc>().add(FavoritesUpdated([]));
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  void setPageIndex(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: _currentPageIndex == 0 ? _buildAppBar(context) : null,
      body: IndexedStack(
        index: _currentPageIndex,
        children: _pages,
      ),
      bottomNavigationBar: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) { // Получаем authState здесь
          return NavigationBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedIndex: _currentPageIndex,
            onDestinationSelected: (index) {
              if (index == 1 && authState is! Authenticated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please sign in to view favorites')),
                );
                return;
              }
              setState(() {
                _currentPageIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.star), label: 'Favorites'),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profile',),
            ],
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      title: Text(widget.title),
      actions: [
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  themeProvider.themeMode == ThemeMode.dark
                      ? Icons.nightlight_round
                      : Icons.wb_sunny,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Switch(
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                  activeColor: Colors.yellow,
                  inactiveThumbColor: Colors.black,
                ),
              ],
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary, // Цвет текста оси X
            ),
            decoration: InputDecoration(
              hintText: 'Search cryptocurrencies...',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                fontSize: 18
              ),
              prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onPrimary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (query) {
              _cryptoListBloc.add(SearchCryptoList(query));
            },
          ),
        ),
      ),
    );
  }
}

class _CryptoListContent extends StatelessWidget {
  const _CryptoListContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CryptoListBloc, CryptoListState>(
      builder: (context, state) {
        if (state is CryptoListLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is CryptoListLoadingFailure) {
          return Center(child: Text('Error: ${state.exception}'));
        }
        if (state is CryptoListLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<CryptoListBloc>().add(LoadCryptoList());
            },
            child: ListView.builder(
              itemCount: state.filteredCoins.length,
              itemBuilder: (context, index) {
                final coin = state.filteredCoins[index];
                return CryptoCoinTile(coin: coin);
              },
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}