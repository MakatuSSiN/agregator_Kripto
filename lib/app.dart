import 'package:agregator_kripto/features/crypto_coin/bloc/crypto_chart/crypto_chart_bloc.dart';
import 'package:agregator_kripto/features/crypto_coin/bloc/crypto_coin_details/crypto_coin_details_bloc.dart';
import 'package:agregator_kripto/repositories/crypto_coins/abstract_coins_repository.dart';
import 'package:agregator_kripto/repositories/crypto_coins/crypto_candle_repository.dart';
import 'package:agregator_kripto/repositories/favorites_repository.dart';
import 'package:agregator_kripto/router/router.dart';
import 'package:agregator_kripto/theme/theme.dart';
import 'package:agregator_kripto/theme/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/crypto_list/bloc/crypto_list_bloc.dart';
import 'features/favorites/bloc/favorites_bloc.dart';


class CryptoApp extends StatelessWidget {
  const CryptoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // AuthBloc должен быть первым, так как от него зависят другие BLoCs
        BlocProvider(
          create: (context) => AuthBloc(GetIt.I<AuthRepository>())
            ..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (context) => CryptoListBloc(GetIt.I<AbstractCoinsRepository>())
            ..add(LoadCryptoList()),
        ),
        // FavoritesBloc зависит от аутентификации
        BlocProvider(
          create: (context) => FavoritesBloc(
            favoritesRepository: GetIt.I<FavoritesRepository>(),
            firebaseAuth: FirebaseAuth.instance,
          ),
        ),
        // Остальные BLoCs
        BlocProvider(
          create: (context) => CryptoChartBloc(GetIt.I<CryptoCandleRepository>()),
        ),
        BlocProvider(
          create: (context) => CryptoCoinDetailsBloc(
            GetIt.I<AbstractCoinsRepository>(),
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'CRYPTO APP',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: routes,
          );
        },
      ),
    );
  }
}