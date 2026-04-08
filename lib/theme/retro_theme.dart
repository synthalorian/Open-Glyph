import 'package:flutter/material.dart';

class RetroTheme {
  static const Color background = Color(0xFF1B1B2F);
  static const Color surface = Color(0xFF242440);
  static const Color surfaceLight = Color(0xFF2D2D52);
  static const Color pixel = Color(0xFF44FF44);
  static const Color pixelDim = Color(0xFF226622);
  static const Color amber = Color(0xFFFFB000);
  static const Color cyan = Color(0xFF00DDFF);
  static const Color white = Color(0xFFE8E8E8);
  static const Color grid = Color(0xFF333355);
  static const Color textPrimary = Color(0xFFDDDDEE);
  static const Color textSecondary = Color(0xFF888899);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: pixel,
          secondary: amber,
          surface: surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: pixel,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: amber,
          foregroundColor: Colors.black,
        ),
        useMaterial3: true,
      );
}
