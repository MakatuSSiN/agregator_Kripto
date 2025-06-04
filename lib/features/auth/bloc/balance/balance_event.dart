part of 'balance_bloc.dart';

abstract class BalanceEvent extends Equatable {
  const BalanceEvent();

  @override
  List<Object> get props => [];
}

class LoadBalance extends BalanceEvent {}

class UpdateBalance extends BalanceEvent {
  final double amount;
  final bool isSpending;

  const UpdateBalance(this.amount, this.isSpending);

  @override
  List<Object> get props => [amount, isSpending];
}
class CheckBalance extends BalanceEvent {
  final double amountToCheck;

  const CheckBalance(this.amountToCheck);

  @override
  List<Object> get props => [amountToCheck];
}