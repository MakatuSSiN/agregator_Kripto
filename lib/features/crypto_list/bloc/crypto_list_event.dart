part of 'crypto_list_bloc.dart';

abstract class CryptoListEvent extends Equatable {
  const CryptoListEvent();
  @override
  List<Object?> get props => [];
}

class LoadCryptoList extends CryptoListEvent {}

class RefreshCryptoList extends CryptoListEvent {}

class SearchCryptoList extends CryptoListEvent {
  final String query;
  const SearchCryptoList(this.query);
  @override
  List<Object?> get props => [query];
}