import 'package:agregator_kripto/features/crypto_coin/bloc/crypto_chart/crypto_chart_bloc.dart';
import 'package:agregator_kripto/features/crypto_coin/bloc/crypto_coin_details/crypto_coin_details_bloc.dart';
import 'package:agregator_kripto/repositories/crypto_coins/abstract_coins_repository.dart';
import 'package:agregator_kripto/repositories/crypto_coins/crypto_candle_repository.dart';
import 'package:agregator_kripto/router/router.dart';
import 'package:agregator_kripto/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/crypto_list/bloc/crypto_list_bloc.dart';


class CryptoApp extends StatelessWidget {
  const CryptoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => CryptoListBloc(GetIt.I<AbstractCoinsRepository>())
            ..add(LoadCryptoList()),
        ),
        BlocProvider(
          create: (context) => AuthBloc(GetIt.I<AuthRepository>()),
        ),
        BlocProvider(
          create: (context) => CryptoChartBloc(GetIt.I<CryptoCandleRepository>()),
        ),
        BlocProvider(  // Добавьте этот провайдер
          create: (context) => CryptoCoinDetailsBloc(
            GetIt.I<AbstractCoinsRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CRYPTO APP',
        theme: darkTheme,
        initialRoute: '/',
        routes: routes,
      ),
    );
  }
}