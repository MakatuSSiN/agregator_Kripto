import 'package:agregator_kripto/features/crypto_list/widgets/crypto_coin_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  @override
  void initState() {
    super.initState();
    _cryptoListBloc = context.read<CryptoListBloc>();
    //_cryptoListBloc.add(LoadCryptoList());
    context.read<CryptoListBloc>().add(LoadCryptoList());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search cryptocurrencies...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (query) {
                context.read<CryptoListBloc>().add(SearchCryptoList(query));
              },
            ),
          ),
        ),
      ),
      body: _buildCurrentPage(),
        bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
      setState(() {
        _currentPageIndex = index;
      });
    },
    selectedIndex: _currentPageIndex,
    destinations: const [
    NavigationDestination(
    icon: Icon(Icons.home),
    label: 'Home',
    ),
    NavigationDestination(
    icon: Icon(Icons.person),
    label: 'Profile',
    ),
    ],
    ),
    );
  }
    Widget _buildCurrentPage() {
      switch (_currentPageIndex) {
        case 0:

    return BlocBuilder<CryptoListBloc, CryptoListState>(
      bloc: _cryptoListBloc,
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
          )
          );
        }
        return const SizedBox();
      },
    );
        case 1: // Profile
          return const Center(child: Text('Profile Page'));
        default:
          return const SizedBox();
}
}}