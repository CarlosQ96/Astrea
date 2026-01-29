import 'package:flutter/material.dart';

import 'astrea_colors.dart';

/// Astrea app theme configuration.
class AstreaTheme {
  AstreaTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AstreaColors.nightSky,
      colorScheme: const ColorScheme.dark(
        primary: AstreaColors.starlightCyan,
        onPrimary: AstreaColors.deepVoid,
        secondary: AstreaColors.oracleGold,
        onSecondary: AstreaColors.deepVoid,
        surface: AstreaColors.astralPurple,
        onSurface: AstreaColors.starWhite,
        error: AstreaColors.error,
        onError: AstreaColors.starWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AstreaColors.deepVoid,
        foregroundColor: AstreaColors.starWhite,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AstreaColors.astralPurple,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AstreaColors.starlightCyan,
          foregroundColor: AstreaColors.deepVoid,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AstreaColors.starlightCyan,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AstreaColors.astralPurple,
        hintStyle: const TextStyle(color: AstreaColors.faded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AstreaColors.starlightCyan,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AstreaColors.deepVoid,
        selectedItemColor: AstreaColors.starlightCyan,
        unselectedItemColor: AstreaColors.faded,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AstreaColors.starlightCyan,
        foregroundColor: AstreaColors.deepVoid,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AstreaColors.starWhite,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AstreaColors.starWhite,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: AstreaColors.starWhite,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(color: AstreaColors.starWhite),
        bodyLarge: TextStyle(color: AstreaColors.starWhite),
        bodyMedium: TextStyle(color: AstreaColors.mist),
        bodySmall: TextStyle(color: AstreaColors.faded),
      ),
      dividerTheme: const DividerThemeData(
        color: AstreaColors.mysticViolet,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: AstreaColors.mist),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AstreaColors.mysticViolet,
        contentTextStyle: const TextStyle(color: AstreaColors.starWhite),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
