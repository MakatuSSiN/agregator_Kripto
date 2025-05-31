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
      emit(AuthError(e.toString()));
    }
  }
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

  Future<void> signInWithStoredCredentials({
    required String email,
    required String password,
  }) async {
    add(SignInRequested(email, password));
  }
  Future<void> _signIn(SignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signIn(event.email, event.password);
      if (user != null) {
        if (user.emailVerified) {
          // Добавляем загрузку избранных после успешного входа

          emit(Authenticated(user));
        } else {
          await authRepository.resendVerificationEmail();
          emit(EmailNotVerified(user.email ?? event.email));
        }
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _signUp(SignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signUp(event.email, event.password);
      if (user != null) {
        emit(EmailVerificationSent(event.email));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _signOut(SignOutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await authRepository.signOut();
    emit(Unauthenticated());
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
      emit(AuthError(e.toString()));
    }
  }
}