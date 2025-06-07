//ignore: depend_on_referenced_packages
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agregator_kripto/features/auth/repositories/auth_repository.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../main.dart';
import '../../favorites/bloc/favorites_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC для управления аутентификацией пользователя
/// Обрабатывает вход, регистрацию, выход, проверку email и другие связанные операции
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc(this.authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_authCheck);
    on<SignInRequested>(_signIn);
    on<SignUpRequested>(_signUp);
    on<SignOutRequested>(_signOut);
    on<ResendVerificationRequested>(_resendVerification);
    on<LoadFavoritesRequested>(_loadFavorites);
  }

  /// Проверка текущего состояния аутентификации
  Future<void> _authCheck(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        if (user.emailVerified) {
          emit(Authenticated(user));
          add(LoadFavoritesRequested());
        } else {
          emit(EmailNotVerified(user.email ?? ''));
        }
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e is AuthException ? e.message : e.toString()));
    }
  }

  /// Загрузка избранного для аутентифицированного пользователя
  Future<void> _loadFavorites(LoadFavoritesRequested event, Emitter<AuthState> emit) async {
    try {
      if (state is Authenticated) {
        final user = (state as Authenticated).user;
        if (user.emailVerified) {
          // Используем прямое обращение к FavoritesBloc
          final favoritesBloc = getIt<FavoritesBloc>();
          favoritesBloc.add(LoadFavorites());
        }
      }
    } catch (e) {
      debugPrint('Failed to load favorites: $e');
    }
  }

  /// Вход с сохраненными учетными данными
  Future<void> signInWithStoredCredentials({
    required String email,
    required String password,
  }) async {
    add(SignInRequested(email, password));
  }

  /// Обработка входа пользователя
  Future<void> _signIn(SignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signIn(event.email, event.password);
      if (user != null) {
        if (user.emailVerified) {
          emit(Authenticated(user));
          // Пересоздаем FavoritesBloc для активации подписки
          getIt.resetLazySingleton<FavoritesBloc>();
          getIt<FavoritesBloc>().add(LoadFavorites());
        } else {
          await authRepository.resendVerificationEmail();
          emit(EmailNotVerified(user.email ?? event.email));
        }
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Обработка регистрации пользователя
  Future<void> _signUp(SignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signUp(event.email, event.password);
      if (user != null) {
        emit(EmailVerificationSent(event.email));
      }
    } catch (e) {
      emit(AuthError(e is AuthException ? e.message : e.toString()));
    }
  }

  /// Обработка выхода пользователя
  Future<void> _signOut(SignOutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Полностью сбрасываем состояние избранных
      final favoritesBloc = getIt<FavoritesBloc>();
      favoritesBloc.add(FavoritesUpdated([]));
      await Future.delayed(Duration.zero); // Даем время на обработку

      await authRepository.signOut();
      emit(Unauthenticated());

      // Пересоздаем FavoritesBloc для чистого состояния
      getIt.resetLazySingleton<FavoritesBloc>();
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _resendVerification(
      ResendVerificationRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      await authRepository.resendVerificationEmail();
      emit(EmailVerificationSent(event.email));
    } catch (e) {
      emit(AuthError(e is AuthException ? e.message : e.toString()));
    }
  }
}