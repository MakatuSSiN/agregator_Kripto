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
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _currentPageIndex,
        onIndexChanged: (index) {
          setState(() => _currentPageIndex = index);
        },
      ),
    );
  }

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