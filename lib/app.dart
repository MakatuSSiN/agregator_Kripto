import 'package:agregator_kripto/router/router.dart';
import 'package:agregator_kripto/theme/theme.dart';
import 'package:flutter/material.dart';

class CryptoApp extends StatelessWidget {
  const CryptoApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'CRYPTO APP MOBILE',
        theme: darkTheme,
        routes: routes

    );
  }
}