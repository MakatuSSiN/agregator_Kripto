import 'package:agregator_kripto/app.dart';
import 'package:agregator_kripto/repositories/crypto_coins/abstract_coins_repository.dart';
import 'package:agregator_kripto/repositories/crypto_coins/crypto_candle_repository.dart';
import 'package:agregator_kripto/repositories/crypto_coins/crypto_coins_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'firebase_options.dart';
final getIt = GetIt.instance;
void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  _setupDependencies();
  runApp(const CryptoApp());
}
void _setupDependencies() {

  getIt.registerLazySingleton<Dio>(() => Dio());
  getIt.registerLazySingleton<AbstractCoinsRepository>(
        () => CryptoCoinsRepository(dio: getIt<Dio>()),
  );
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());
  getIt.registerFactory<AuthBloc>(() => AuthBloc(getIt<AuthRepository>()));
  getIt.registerLazySingleton<CryptoCandleRepository>(
        () => CryptoCandleRepository(getIt<Dio>()),
  );
}







