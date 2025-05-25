import 'dart:async';
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/crypto_coin.dart';
import 'package:agregator_kripto/repositories/favorites_repository.dart';

part 'favorites_event.dart';
part 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoritesRepository favoritesRepository;
  final FirebaseAuth firebaseAuth;
  StreamSubscription? _favoritesSubscription;

  FavoritesBloc({
    required this.favoritesRepository,
    required this.firebaseAuth,
  }) : super(FavoritesInitial()) {
    on<LoadFavorites>(_loadFavorites);
    on<ToggleFavorite>(_toggleFavorite);
    on<FavoritesUpdated>(_onFavoritesUpdated);

    _subscribeToFavorites();
  }

  void _subscribeToFavorites() {
    _favoritesSubscription?.cancel();
    _favoritesSubscription = favoritesRepository.watchFavorites().listen(
          (favorites) {
        if (favorites.isEmpty && firebaseAuth.currentUser == null) {
          add(FavoritesUpdated([], isAuthenticated: false));
        } else {
          add(FavoritesUpdated(favorites));
        }
      },
      onError: (error) => add(FavoritesUpdated([], error: error.toString())),
    );
  }

  void _onFavoritesUpdated(FavoritesUpdated event, Emitter<FavoritesState> emit) {
    if (event.error != null) {
      emit(FavoritesError(event.error!));
    } else {
      emit(FavoritesLoaded(event.favorites));
    }
  }

  Future<void> _toggleFavorite(
      ToggleFavorite event,
      Emitter<FavoritesState> emit,
      ) async {
    try {
      if (event.coin.isFavorite) {
        await favoritesRepository.removeFavorite(event.coin);
      } else {
        await favoritesRepository.addFavorite(event.coin);
      }
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }
  Future<void> _loadFavorites(
      LoadFavorites event,
      Emitter<FavoritesState> emit,
      ) async {
    if (firebaseAuth.currentUser == null) {
      emit(FavoritesUnauthenticated());
      return;
    }

    emit(FavoritesLoading());
    try {
      final favorites = await favoritesRepository.getFavorites();
      emit(FavoritesLoaded(favorites));
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }
  @override
  Future<void> close() {
    _favoritesSubscription?.cancel();
    return super.close();
  }
}