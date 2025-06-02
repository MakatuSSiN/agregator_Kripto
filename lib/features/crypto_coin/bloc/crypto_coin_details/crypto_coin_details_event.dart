part of 'crypto_coin_details_bloc.dart';

abstract class CryptoCoinDetailsEvent extends Equatable {
  const CryptoCoinDetailsEvent();

  @override
  List<Object> get props => [];
}

class LoadCryptoCoinDetails extends CryptoCoinDetailsEvent {
  const LoadCryptoCoinDetails({
    required this.currencyCode,
  });

  final String currencyCode;

  @override
  List<Object> get props => super.props..add(currencyCode);
}

class StartAutoRefresh extends CryptoCoinDetailsEvent {
  const StartAutoRefresh({
    required this.currencyCode,
    this.intervalSeconds = 12,
  });

  final String currencyCode;
  final int intervalSeconds;

  @override
  List<Object> get props => super.props..addAll([currencyCode, intervalSeconds]);
}

class StopAutoRefresh extends CryptoCoinDetailsEvent {
  const StopAutoRefresh();
}