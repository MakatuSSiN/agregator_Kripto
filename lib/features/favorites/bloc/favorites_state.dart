part of 'favorites_bloc.dart';

abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object> get props => [];
}

class FavoritesInitial extends FavoritesState {}
class FavoritesLoading extends FavoritesState {}
class FavoritesUnauthenticated extends FavoritesState {}
class FavoritesError extends FavoritesState {
  final String message;
  const FavoritesError(this.message);

  @override
  List<Object> get props => [message];
}
class FavoritesLoaded extends FavoritesState {
  final List<CryptoCoin> favorites;
  const FavoritesLoaded(this.favorites);

  @override
  List<Object> get props => [favorites];
}
class FavoriteToggled extends FavoritesState {
  final CryptoCoin updatedCoin;
  const FavoriteToggled(this.updatedCoin);

  @override
  List<Object> get props => [updatedCoin];
}