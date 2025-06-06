import 'package:agregator_kripto/features/crypto_coin/crypto_coin.dart';
import 'package:agregator_kripto/features/crypto_list/crypto_list.dart';

import '../features/auth/view/auth_screen.dart';
import '../features/favorites/view/favorites_screen.dart';

final routes = {
  "/": (context) => const CryptoListScreen(title: "OMGEx"),
  "/coin": (context) => const CryptoCoinScreen(),
  "/profile": (context) => const AuthScreen(),
  "/favorites": (context) => const FavoritesScreen(),
};