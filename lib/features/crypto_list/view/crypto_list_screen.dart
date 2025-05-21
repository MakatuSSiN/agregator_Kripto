import 'package:agregator_kripto/features/crypto_list/widgets/crypto_coin_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/view/auth_screen.dart';
import '../bloc/crypto_list_bloc.dart';

class CryptoListScreen extends StatefulWidget {
  const CryptoListScreen({super.key, required this.title});
  final String title;

  @override
  State<CryptoListScreen> createState() => _CryptoListScreenState();
}

class _CryptoListScreenState extends State<CryptoListScreen> {
  int _currentPageIndex = 0;
  final _searchController = TextEditingController();
  late final CryptoListBloc _cryptoListBloc;

  final List<Widget> _pages = [
    const _CryptoListContent(),
    const AuthScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _cryptoListBloc = context.read<CryptoListBloc>();
    _cryptoListBloc.add(LoadCryptoList());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentPageIndex == 0 ? _buildAppBar() : null,
      body: IndexedStack(
        index: _currentPageIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentPageIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(widget.title),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search cryptocurrencies...',
              prefixIcon: const Icon(Icons.search),
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