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
        )
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
      backgroundColor: Colors.blue.shade700,
      titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800
      ),
      iconTheme: const IconThemeData(color: Colors.white)
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.blue.shade700,
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white.withValues(alpha: 0.6),
  ),
);