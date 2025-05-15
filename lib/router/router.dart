import 'package:agregator_kripto/features/crypto_coin/crypto_coin.dart';
import 'package:agregator_kripto/features/crypto_list/crypto_list.dart';

final routes = {
  "/": (context) => const CryptoListScreen(title: "CRYPTO ROCKET"),
  "/coin": (context) => const CryptoCoinScreen(),
};