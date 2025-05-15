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