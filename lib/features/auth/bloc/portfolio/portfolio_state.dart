part of 'portfolio_bloc.dart';

abstract class PortfolioState extends Equatable {
  const PortfolioState();

  @override
  List<Object> get props => [];
}

class PortfolioInitial extends PortfolioState {}

class PortfolioLoading extends PortfolioState {}

class PortfolioLoaded extends PortfolioState {
  final List<PortfolioItem> portfolioItems;
  const PortfolioLoaded(this.portfolioItems);

  @override
  List<Object> get props => [portfolioItems];
}

class PortfolioLoadFailure extends PortfolioState {
  final String message;
  const PortfolioLoadFailure(this.message);

  @override
  List<Object> get props => [message];
}