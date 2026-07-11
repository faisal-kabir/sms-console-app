import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const double tapTargetMin = 48.0;
  static const double borderRadius = 16.0;
  static const double buttonHeight = 52.0;
}

class AppColors {
  // Light Palette
  static const Color primaryLight = Color(0xFF6366F1); // Indigo
  static const Color secondaryLight = Color(0xFF8B5CF6); // Purple
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF475569); // Slate 600
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200

  // Dark Palette
  static const Color primaryDark = Color(0xFF818CF8); // Indigo Light
  static const Color secondaryDark = Color(0xFFA78BFA); // Purple Light
  static const Color backgroundDark = Color(0xFF0B0F19); // Deep Slate
  static const Color surfaceDark = Color(0xFF151D30); // Slate 800-ish
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color borderDark = Color(0xFF334155); // Slate 700

  // Semantic
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryLight,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
      ),
      textTheme: ThemeData.light().textTheme.copyWith(
            titleLarge: const TextStyle(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
            titleMedium: const TextStyle(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            bodyLarge: const TextStyle(
              color: AppColors.textPrimaryLight,
              fontSize: 15,
            ),
            bodyMedium: const TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 13,
            ),
          ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.m,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondaryLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryDark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDark,
        secondary: AppColors.secondaryDark,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
      ),
      textTheme: ThemeData.dark().textTheme.copyWith(
            titleLarge: const TextStyle(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
            titleMedium: const TextStyle(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            bodyLarge: const TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 15,
            ),
            bodyMedium: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 13,
            ),
          ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.m,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.backgroundDark,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
