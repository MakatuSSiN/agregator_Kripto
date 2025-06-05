import 'package:flutter/material.dart';

final darkTheme = ThemeData(
  colorScheme: _darkColorScheme,
  textTheme: TextTheme(
    //displayLarge: TextStyle(color: _darkColorScheme.onBackground),
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
  cardTheme: CardTheme(color: Colors.black,)
);

final lightTheme = ThemeData(
  colorScheme: _lightColorScheme,
  textTheme: TextTheme(
    //displayLarge: TextStyle(color: _darkColorScheme.onBackground),
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
  cardTheme: CardTheme(color: Colors.grey.shade300,)

);


final _darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  // Основные цвета
  primary: Colors.grey.shade900,
  onPrimary: Colors.grey.shade50,
  // primaryContainer: Colors.yellow.withOpacity(0.2),
  // onPrimaryContainer: Colors.yellow,
  // Второстепенные цвета
  secondary: Colors.yellow,
  onSecondary: Colors.grey.shade900,
  // secondaryContainer: Colors.grey.shade800,
  // onSecondaryContainer: Colors.yellow,
  // Фон и поверхности
  surface: Colors.grey.shade800,
  onSurface: Colors.grey.shade600,
  // surfaceContainerHighest: Colors.grey.shade700,
  //onSurfaceVariant: Colors.black,
  // Ошибки и состояния
  error: Colors.red.shade400,
  onError: Colors.grey.shade50,
  // errorContainer: Colors.red.shade900,
  // onErrorContainer: Colors.red.shade100,
  // Дополнительные
  // outline: Colors.grey.shade600,
  // shadow: Colors.black,
);

// Светлая тема
final _lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  // Основные цвета
  primary: Colors.grey.shade50,
  onPrimary: Colors.black,
  // primaryContainer: Colors.grey.shade200,
  // onPrimaryContainer: Colors.black,
  // Второстепенные цвета
  secondary: Colors.black,
  onSecondary: Colors.grey.shade50,
  // secondaryContainer: Colors.grey.shade300,
  // onSecondaryContainer: Colors.grey.shade800,
  // Фон и поверхности
  surface: Colors.grey.shade300,
  onSurface: Colors.grey.shade600,
  // surfaceContainerHighest: Colors.grey.shade200,
  //onSurfaceVariant: Colors.grey.shade300,
  // Ошибки и состояния
  error: Colors.red.shade700,
  onError: Colors.white,
  // errorContainer: Colors.red.shade100,
  // onErrorContainer: Colors.red.shade900,
  // // Дополнительные
  // outline: Colors.grey.shade400,
  // shadow: Colors.grey.shade600,
);