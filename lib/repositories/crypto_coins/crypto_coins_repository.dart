import 'package:agregator_kripto/repositories/crypto_coins/abstract_coins_repository.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/crypto_coin.dart';
import 'package:agregator_kripto/repositories/crypto_coins/models/crypto_coin_details.dart';
import 'package:dio/dio.dart';

class CryptoCoinsRepository implements AbstractCoinsRepository {
  final Dio dio;

  CryptoCoinsRepository({required this.dio});

  @override
  Future<List<CryptoCoin>> getCoinsList() async {
    final response = await dio.get(
        "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=BTC,ETH,BNB,SOL,LTC,TON,XRP,TRX,SUI,DOGE&tsyms=USD"
    );

    final data = response.data as Map<String, dynamic>;
    final dataRaw = data["RAW"] as Map<String, dynamic>;

    return dataRaw.entries.map((e) {
      final usdData = (e.value as Map<String, dynamic>)["USD"] as Map<String, dynamic>;
      return CryptoCoin(
        name: e.key,
        priceInUSD: usdData["PRICE"],
        imageUrl: "https://www.cryptocompare.com${usdData["IMAGEURL"]}",
        symbol: e.key,
      );
    }).toList();
  }

  @override
  Future<CryptoCoinDetail> getCoinDetails(String currencyCode) async {
    final response = await dio.get(
        'https://min-api.cryptocompare.com/data/pricemultifull?fsyms=$currencyCode&tsyms=USD');

    final data = response.data as Map<String, dynamic>;
    final dataRaw = data['RAW'] as Map<String, dynamic>;
    final coinData = dataRaw[currencyCode] as Map<String, dynamic>;
    final usdData = coinData['USD'] as Map<String, dynamic>;

    return CryptoCoinDetail(
      name: currencyCode,
      priceInUSD: usdData['PRICE'],
      imageUrl: 'https://www.cryptocompare.com/${usdData["IMAGEURL"]}',
      toSymbol: usdData['TOSYMBOL'],
      lastUpdate: DateTime.fromMillisecondsSinceEpoch(usdData['LASTUPDATE'] * 1000),
      high24Hour: usdData['HIGH24HOUR'],
      low24Hour: usdData['LOW24HOUR'],
    );
  }


}