import 'package:equatable/equatable.dart';

class CryptoCoin extends Equatable {
  const CryptoCoin({
    required this.name,
    required this.priceInUSD,
    required this.imageUrl,
    required this.symbol,
  });

  final String name;
  final double priceInUSD;
  final String imageUrl;
  final String symbol;

  @override
  List<Object> get props => [name, priceInUSD, imageUrl];
}
