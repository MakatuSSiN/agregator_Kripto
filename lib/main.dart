import 'package:agregator_kripto/app.dart';
import 'package:agregator_kripto/repositories/crypto_coins/abstract_coins_repository.dart';
import 'package:agregator_kripto/repositories/crypto_coins/crypto_coins_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

void main() {
  GetIt.I.registerLazySingleton<AbstractCoinsRepository> (() => CryptoCoinsRepository(dio: Dio()));
  runApp(const CryptoApp());
}







