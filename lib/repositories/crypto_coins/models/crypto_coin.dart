import 'package:equatable/equatable.dart';

class CryptoCoin extends Equatable{
  final String name;      // Название валюты (USD, JPY, EUR)
  final double priceInUSD; // Курс
  final String imageUrl;

  CryptoCoin({
    required this.name,
    required this.priceInUSD,
    required this.imageUrl
  });

  @override
  // TODO: implement props
  List<Object> get props => [name, priceInUSD, imageUrl];
}
