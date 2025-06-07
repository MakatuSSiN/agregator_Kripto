part of 'portfolio_bloc.dart';

abstract class PortfolioEvent extends Equatable {
  const PortfolioEvent();

  @override
  List<Object> get props => [];
}

class LoadPortfolio extends PortfolioEvent {}

class PortfolioUpdated extends PortfolioEvent {
  final List<DocumentSnapshot> docs;
  const PortfolioUpdated(this.docs);

  @override
  List<Object> get props => [docs];
}