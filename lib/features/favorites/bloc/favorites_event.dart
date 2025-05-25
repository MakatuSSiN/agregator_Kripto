part of 'favorites_bloc.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object> get props => [];
}

class LoadFavorites extends FavoritesEvent {}

class ToggleFavorite extends FavoritesEvent {
  final CryptoCoin coin;

  const ToggleFavorite(this.coin);

  @override
  List<Object> get props => [coin];
}

class FavoritesUpdated extends FavoritesEvent {
  final List<CryptoCoin> favorites;
  final String? error;

  const FavoritesUpdated(this.favorites, {this.error});

  @override
  List<Object> get props => [
    favorites,
    if (error != null) error!,
  ];
}