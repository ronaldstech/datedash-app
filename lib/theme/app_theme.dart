import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // For Android
          statusBarBrightness: Brightness.light, // For iOS
        ),
      ),
    );
  }
}
