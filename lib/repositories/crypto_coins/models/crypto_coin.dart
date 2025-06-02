import 'package:equatable/equatable.dart';

class CryptoCoin extends Equatable {
  const CryptoCoin({
    required this.name,
    required this.priceInUSD,
    required this.imageUrl,
    required this.symbol,
    this.isFavorite = false,
  });

  final String name;
  final double priceInUSD;
  final String imageUrl;
  final String symbol;
  final bool isFavorite;
  Map<String, dynamic> toJson() => {
    'name': name,
    'priceInUSD': priceInUSD,
    'imageUrl': imageUrl,
    'symbol': symbol,
    'isFavorite': isFavorite,
  };
  factory CryptoCoin.fromJson(Map<String, dynamic> json) => CryptoCoin(
    name: json['name'] as String,
    priceInUSD: json['priceInUSD'] as double,
    imageUrl: json['imageUrl'] as String,
    symbol: json['symbol'] as String,
    isFavorite: json['isFavorite'] as bool? ?? false,
  );
  CryptoCoin copyWith({
    bool? isFavorite,
  }) => CryptoCoin(
    name: name,
    priceInUSD: priceInUSD,
    imageUrl: imageUrl,
    symbol: symbol,
    isFavorite: isFavorite ?? this.isFavorite,
  );

  @override
  List<Object> get props => [name, priceInUSD, imageUrl];
}
