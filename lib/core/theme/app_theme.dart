import 'package:flutter/material.dart';

class AppTheme {
  // Original Saffron Palette (for reference)
  static const Color saffronPrimary = Color(0xFFFF6F00);
  static const Color saffronDark = Color(0xFFE65100);
  static const Color amberWarm = Color(0xFFFFB300);
  
  // Depth Colors
  static const Color backgroundDeep = Color(0xFF000000); // Pure Black for Dark Mode
  static const Color surfaceGlass = Color(0xFF121212); // Elevated surface
  
  static const double borderRadius = 32.0;
  static const double buttonRadius = 20.0;
  
  static ThemeData darkTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDeep,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        brightness: Brightness.dark,
        surface: surfaceGlass,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: Color(0xFFE0E0E0),
          height: 1.6,
        ),
        labelLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  static ThemeData lightTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFFFFF), // Pure White for "Paper" feel
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        brightness: Brightness.light,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: Color(0xFF000000),
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Color(0xFF000000),
          letterSpacing: -0.2,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          color: Color(0xFF000000), // Pure Black for max contrast
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: Color(0xFF111111), // Strongest grey/black
          height: 1.6,
        ),
        labelLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
