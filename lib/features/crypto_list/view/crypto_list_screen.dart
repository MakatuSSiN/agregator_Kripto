import 'package:agregator_kripto/features/crypto_list/widgets/crypto_coin_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/view/auth_screen.dart';
import '../../favorites/bloc/favorites_bloc.dart';
import '../../favorites/view/favorites_screen.dart';
import '../bloc/crypto_list_bloc.dart';
import '../widgets/widgets.dart';

/// Основной экран приложения с навигацией между:
/// Списком криптовалют, избранным, профилем
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
  bool _showNavigation = true;
  void changePage(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }
  /// Список страниц приложения
  final List<Widget> _pages = [
    const _CryptoListContent(),
    const FavoritesScreen(),
    const AuthScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Инициализация BLoC и загрузка данных
    _cryptoListBloc = context.read<CryptoListBloc>();
    _cryptoListBloc.add(LoadCryptoList());
    _cryptoListBloc.stream.listen((state) { //для экрана без интернета
      if (state is CryptoListLoadingFailure && state.isConnectionError) {
        setState(() {
          _showNavigation = false; // Скрываем навигацию при ошибке соединения
        });
      } else {
        setState(() {
          _showNavigation = true; // Показываем навигацию в других случаях
        });
      }
    });
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

  /// Установка индекса текущей страницы
  void setPageIndex(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      // AppBar только для главной страницы
      appBar: _showNavigation && _currentPageIndex == 0
          ? _buildAppBar(context)
          : null,
      body: IndexedStack(
        index: _currentPageIndex,
        children: _pages,
      ),
      bottomNavigationBar: _showNavigation
          ? CustomNavigationBar(
        currentIndex: _currentPageIndex,
        onIndexChanged: (index) {
          setState(() => _currentPageIndex = index);
        },
      )
          : null,
    );
  }

  /// Построение AppBar для главной страницы
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      title: Text(
        widget.title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 26,
        ),
      ),
      leading: SizedBox(
        width: 60,
        height: 60,
        child: Image.asset(
          "assets/logoOMGEX.png",
          fit: BoxFit.cover,
        ),
      ),
      actions: const [ThemeSwitcher()],
      bottom: CryptoSearchBar(
        controller: _searchController,
        onSearchChanged: (query) {
          _cryptoListBloc.add(SearchCryptoList(query));
        },
      ),
    );
  }
}

/// Виджет содержимого главной страницы с криптовалютами
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
          if (state.isConnectionError) {
            return Container(
              color: Theme.of(context).colorScheme.primary,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Нет соединения с интернетом',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        context.read<CryptoListBloc>().add(LoadCryptoList());
                      },
                      child: const Text('Повторить попытку'),
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(child: Text('Ошибка: ${state.exception}'));
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