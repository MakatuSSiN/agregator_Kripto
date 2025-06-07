import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/portfolio/portfolio_bloc.dart';

class PortfolioList extends StatelessWidget {
  const PortfolioList({super.key});

  @override
  Widget build(BuildContext context) {
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
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                subtitle: Text(
                  item.amount.toStringAsFixed(4),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            },
          );
        }
        return const SizedBox();
      },
    );
  }
}