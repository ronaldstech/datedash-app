import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF4D85), // Premium Pink
        primary: const Color(0xFFFF4D85),
        secondary: const Color(0xFFFF85A1),
        background: const Color(0xFFFAFAFA),
        surface: Colors.white,
      ),
      useMaterial3: true,
      fontFamily: 'Roboto', // Default fallback
    );
  }
}
