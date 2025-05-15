import 'package:agregator_kripto/features/crypto_coin/crypto_coin.dart';
import 'package:agregator_kripto/features/crypto_list/crypto_list.dart';

final routes = {
  "/" : (context) => CryptoListScreen(title: "CRYPTO ROCKET",),
  "/coin" : (context) => CryptoCoinScreen(),
};