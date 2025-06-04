import 'package:flutter/material.dart';

final darkTheme = ThemeData(
    dividerColor: Colors.white,
    scaffoldBackgroundColor: Colors.grey.shade900,
    textTheme: TextTheme(
        bodyMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 20,
        ),
        labelSmall: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w700,
            fontSize: 14
        )
    ),
    listTileTheme: ListTileThemeData(
      iconColor: Colors.white
    ),
    appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.grey.shade900,
        titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800
        ),
        iconTheme: const IconThemeData(color: Colors.white)
    ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.grey.shade800,
    indicatorColor: Colors.yellow,
    labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (Set<WidgetState> states) {
        return TextStyle(
          color: states.contains(WidgetState.selected)
              ? Colors.yellow
              : Colors.white.withValues(alpha: 0.4),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        );
      },
    ),
    iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? Colors.grey.shade800
              : Colors.white.withValues(alpha: 0.4),
          size: 24,
        );
      },
    ),
  ),
    cardTheme: CardTheme(
        color: Colors.black
    ),
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.yellow;
        }
        return Colors.grey.shade900;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.grey.shade900;
        }
        return Colors.white.withValues(alpha: 0.4);
      }),
    ),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.yellow,
  ),
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: Colors.yellow,
      onPrimary: Colors.grey.shade900,
      secondary: Colors.yellow,
      onSecondary: Colors.grey.shade900,
      error: Colors.yellow,
      onError: Colors.grey.shade900,
      surface: Colors.yellow,
      onSurface: Colors.grey.shade900
      ,
    )
);

final lightTheme = ThemeData(
  dividerColor: Colors.black,
  scaffoldBackgroundColor: Colors.grey.shade50,
  textTheme: TextTheme(
      bodyMedium: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w500,
        fontSize: 20,
      ),
      labelSmall: TextStyle(
          color: Colors.black.withValues(alpha: 0.8),
          fontWeight: FontWeight.w700,
          fontSize: 14
      )
  ),
  listTileTheme: const ListTileThemeData(
      iconColor: Colors.black
  ),
  appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.grey.shade50,
      titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w800
      ),
      iconTheme: const IconThemeData(color: Colors.black)
  ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.grey.shade300,
      indicatorColor: Colors.black,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
            (Set<WidgetState> states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? Colors.black
                : Colors.black.withValues(alpha: 0.4),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          );
        },
      ),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
            (Set<WidgetState> states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? Colors.grey.shade50
                : Colors.black.withValues(alpha: 0.4),
            size: 24,
          );
        },
      ),
    ),
  cardTheme: CardTheme(
    color: Colors.grey.shade300
  ),
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.grey.shade300;
        }
        return Colors.grey.shade50;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.black;
        }
        return Colors.black.withValues(alpha: 0.6);
      }),
    ),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: Colors.grey.shade300,
    ),
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: Colors.black,
    onPrimary: Colors.grey.shade50,
    secondary: Colors.grey.shade700,
    onSecondary: Colors.white,
    error: Colors.red.shade700,
    onError: Colors.white,
    surface: Colors.grey.shade300,
    onSurface: Colors.black,
     )
  );