// lib/core/theme/app_theme.dart
//
// Flutter uses a "ThemeData" object to define the visual style of the whole app.
// Instead of setting colors/fonts on every widget individually, we define them
// once here and Flutter automatically applies them everywhere.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ─── Light theme (the only theme for LocoFly — matches Figma) ───────────
  static ThemeData get lightTheme {
    // GoogleFonts.interTextTheme() gives us the Inter font applied to all
    // text styles (headline, body, label etc.) at once
    final textTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true, // Use the latest Material Design
      colorScheme: _colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,

      // ─── AppBar ─────────────────────────────────────────────────────────
      // The top bar of each screen. We make it transparent so screens can
      // control their own header look (e.g. the yellow onboarding screen)
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0, // No shadow under app bar
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle:
            SystemUiOverlayStyle.dark, // Status bar icons are dark
      ),

      // ─── ElevatedButton (the filled yellow buttons) ──────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary, // Text color on the button
          minimumSize: const Size(double.infinity, 54), // Full width, 54px tall
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      // ─── OutlinedButton (the bordered pill buttons e.g. "Use Biometric") ─
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ─── TextButton (e.g. "Login now", "Forgot Password?") ───────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── InputDecoration (all text fields: email, password etc.) ─────────
      // Defining this once means every TextField in the app looks consistent
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textTertiary,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),

      // ─── Card ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Bottom navigation bar ────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle:
            GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // ─── Divider ─────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ─── Color scheme (maps brand colors to Material 3 roles) ────────────────
  static const ColorScheme _colorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.textPrimary,
    secondary: AppColors.darkButton,
    onSecondary: AppColors.white,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    error: AppColors.error,
    onError: AppColors.white,
  );
}
