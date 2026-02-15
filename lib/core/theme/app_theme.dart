import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_word/core/constants/app_colors.dart';

/// Futuristic / cyberpunk application theme.
class AppTheme {
  AppTheme._();

  // ─── Typography ────────────────────────────────────────────────────
  static TextTheme _buildTextTheme() {
    final orbitron = GoogleFonts.orbitronTextTheme();
    final rajdhani = GoogleFonts.rajdhaniTextTheme();

    return TextTheme(
      // Headers – Orbitron for the sci-fi feel
      displayLarge: orbitron.displayLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
      ),
      displayMedium: orbitron.displayMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
      displaySmall: orbitron.displaySmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
      headlineLarge: orbitron.headlineLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
      headlineMedium: orbitron.headlineMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: orbitron.headlineSmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),

      // Title & Label – Rajdhani for UI legibility
      titleLarge: rajdhani.titleLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 22,
      ),
      titleMedium: rajdhani.titleMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleSmall: rajdhani.titleSmall?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),

      // Body
      bodyLarge: rajdhani.bodyLarge?.copyWith(
        color: AppColors.textPrimary,
        fontSize: 16,
      ),
      bodyMedium: rajdhani.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
      bodySmall: rajdhani.bodySmall?.copyWith(
        color: AppColors.textMuted,
        fontSize: 12,
      ),

      // Labels
      labelLarge: rajdhani.labelLarge?.copyWith(
        color: AppColors.electricBlue,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 1.2,
      ),
      labelMedium: rajdhani.labelMedium?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      labelSmall: rajdhani.labelSmall?.copyWith(
        color: AppColors.textMuted,
        fontSize: 10,
        letterSpacing: 1.5,
      ),
    );
  }

  // ─── ThemeData ─────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.deepSpace,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.electricBlue,
        secondary: AppColors.cyberPurple,
        surface: AppColors.surfaceDark,
        error: AppColors.warningRed,
        onPrimary: AppColors.deepSpace,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),

      // ── AppBar ──────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.electricBlue),
      ),

      // ── Cards ───────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // ── Elevated Buttons (neon glow CTA) ────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricBlue,
          foregroundColor: AppColors.deepSpace,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          shadowColor: AppColors.electricBlue.withValues(alpha: 0.5),
          textStyle: textTheme.labelLarge?.copyWith(
            color: AppColors.deepSpace,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),

      // ── Outlined Buttons ────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.electricBlue,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          side: const BorderSide(color: AppColors.electricBlue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ── Input Fields ────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.electricBlue, width: 2),
        ),
      ),

      // ── Bottom Navigation ───────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.electricBlue,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Divider ─────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
      ),

      // ── Floating Action Button ──────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.electricBlue,
        foregroundColor: AppColors.deepSpace,
        elevation: 8,
      ),
    );
  }
}

