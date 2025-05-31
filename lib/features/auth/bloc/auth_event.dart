part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;
  const SignInRequested(this.email, this.password);
  @override
  List<Object> get props => [email, password];
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  const SignUpRequested(this.email, this.password);
  @override
  List<Object> get props => [email, password];
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();

  @override
  List<Object> get props => [];
}

class ResendVerificationRequested extends AuthEvent {
  final String email;
  const ResendVerificationRequested(this.email);
  @override
  List<Object> get props => [email];
}
class LoadFavoritesRequested extends AuthEvent {
  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();
}
class AuthCheckRequested extends AuthEvent {
  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();
}