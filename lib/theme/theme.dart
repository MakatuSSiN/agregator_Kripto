import 'package:flutter/material.dart';

final darkTheme = ThemeData(
  colorScheme: _darkColorScheme,
  textTheme: TextTheme(
    bodyMedium: TextStyle(
      color: _darkColorScheme.onPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 20,
    ),
    labelSmall: TextStyle(
      color: _darkColorScheme.onPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 14,
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: _darkColorScheme.surface,
    indicatorColor: _darkColorScheme.secondary,
    labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? _darkColorScheme.secondary
                  : _darkColorScheme.onSurface,
              fontSize: 14
          ),
    ),
  ),
  cardTheme: CardTheme(
    color: Colors.black
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: _darkColorScheme.secondary,
    contentTextStyle: TextStyle(
      color: _darkColorScheme.onSecondary,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),

);

final lightTheme = ThemeData(
  colorScheme: _lightColorScheme,
  textTheme: TextTheme(
    bodyMedium: TextStyle(
      color: _lightColorScheme.onPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 20,
    ),
    labelSmall: TextStyle(
      color: _lightColorScheme.onPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 14,
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: _lightColorScheme.surface,
    indicatorColor: _lightColorScheme.secondary,
    labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? _lightColorScheme.onPrimary
                  : _lightColorScheme.onSurface,
              fontSize: 14
          ),
    ),
  ),
  cardTheme: CardTheme(
    color: Colors.grey.shade300
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: _lightColorScheme.secondary,
    contentTextStyle: TextStyle(
      color: _lightColorScheme.onSecondary,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),

);


final _darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  // Основные цвета
  primary: Colors.grey.shade900,
  onPrimary: Colors.grey.shade50,
  // Второстепенные цвета
  secondary: Colors.yellow,
  onSecondary: Colors.grey.shade900,
  // Фон и поверхности
  surface: Colors.grey.shade800,
  onSurface: Colors.grey.shade600,
  // Ошибки и состояния
  error: Colors.red.shade400,
  onError: Colors.grey.shade50,
);

// Светлая тема
final _lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  // Основные цвета
  primary: Colors.grey.shade50,
  onPrimary: Colors.black,
  // Второстепенные цвета
  secondary: Colors.black,
  onSecondary: Colors.grey.shade50,
  // Фон и поверхности
  surface: Colors.grey.shade300,
  onSurface: Colors.grey.shade600,
  // Ошибки и состояния
  error: Colors.red.shade700,
  onError: Colors.white,

);