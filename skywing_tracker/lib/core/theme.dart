import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0A1628);
  static const accent = Color(0xFFF5A623);
  static const success = Color(0xFF2ECC71);
  static const warning = Color(0xFFF39C12);
  static const error = Color(0xFFE74C3C);
  static const surface = Color(0xFF121F3D);
  static const card = Color(0xFF1A2F4A);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0BEC5);
  static const divider = Color(0xFF263A5A);
}

ThemeData buildDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    cardColor: AppColors.card,
    dividerColor: AppColors.divider,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Rajdhani',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 1.2,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Rajdhani',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Rajdhani',
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Rajdhani',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Rajdhani',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.card,
      selectedColor: AppColors.accent.withOpacity(0.3),
      labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      side: const BorderSide(color: AppColors.divider),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

ThemeData buildLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0A1628),
      secondary: Color(0xFFF5A623),
    ),
  );
}
