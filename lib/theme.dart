import 'package:flutter/material.dart';

class AppTheme {
  static const Color red = Color(0xFFFF3B3B);
  static const Color navy = Color(0xFF001F3F);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color cardDark = Color(0xFF1A1A1A);

  static ThemeData darkTheme() => ThemeData(
    brightness: Brightness.dark,
    primaryColor: red,
    scaffoldBackgroundColor: darkBg,
    cardColor: cardDark,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: red,
        foregroundColor: white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      shadowColor: red.withOpacity(0.3),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(color: white, fontSize: 28, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: navy, fontSize: 20, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: white, fontSize: 16),
    ),
  );
}
