import 'package:agregator_kripto/repositories/crypto_coins/abstract_coins_repository.dart';
import 'package:agregator_kripto/router/router.dart';
import 'package:agregator_kripto/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/crypto_list/bloc/crypto_list_bloc.dart';
import 'main.dart';

class CryptoApp extends StatelessWidget {
  const CryptoApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: [
        BlocProvider(
        create: (context) => CryptoListBloc(getIt<AbstractCoinsRepository>()),
    ),
    ],
    child: MaterialApp(
    title: 'CRYPTO APP',
    theme: darkTheme,
    initialRoute: '/',
    routes: routes
    ));
  }
}