part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);
  @override
  List<Object> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object> get props => [message];
}

class EmailVerificationSent extends AuthState {
  final String email;
  const EmailVerificationSent(this.email);
  @override
  List<Object> get props => [email];
}

class EmailNotVerified extends AuthState {
  final String email;
  const EmailNotVerified(this.email);
  @override
  List<Object> get props => [email];
}
class PasswordResetSent extends AuthState {
  final String email;
  const PasswordResetSent(this.email);

  @override
  List<Object> get props => [email];
}