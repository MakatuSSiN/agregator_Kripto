part of 'crypto_list_bloc.dart';

abstract class CryptoListState extends Equatable {
  const CryptoListState();

  @override
  List<Object> get props => [];
}

class CryptoListInitial extends CryptoListState {}

class CryptoListLoading extends CryptoListState {}

class CryptoListLoaded extends CryptoListState {
  final List<CryptoCoin> coinsList;
  final List<CryptoCoin> filteredCoins;

  const CryptoListLoaded({
    required this.coinsList,
    required this.filteredCoins,
  });

  @override
  List<Object> get props => [coinsList, filteredCoins];
}

class CryptoListLoadingFailure extends CryptoListState {
  final Object exception;
  final bool isConnectionError;

  const CryptoListLoadingFailure(this.exception, {this.isConnectionError = false});

  @override
  List<Object> get props => [exception, isConnectionError];
}