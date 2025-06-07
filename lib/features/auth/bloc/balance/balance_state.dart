part of 'balance_bloc.dart';

abstract class BalanceState extends Equatable {
  const BalanceState();

  @override
  List<Object> get props => [];
}

class BalanceInitial extends BalanceState {}

class BalanceLoading extends BalanceState {}

class BalanceLoaded extends BalanceState {
  final double amount;
  const BalanceLoaded(this.amount);

  @override
  List<Object> get props => [amount];
}

class BalanceOperationSuccess extends BalanceState {
  final double newBalance;
  const BalanceOperationSuccess(this.newBalance);

  @override
  List<Object> get props => [newBalance];
}

class BalanceError extends BalanceState {
  final String message;
  const BalanceError(this.message);

  @override
  List<Object> get props => [message];
}
