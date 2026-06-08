// lib/core/theme/app_colors.dart
//
// All colors used in LocoFly, extracted from the Figma design.
// Using a single file for colors means if the design changes,
// you only update one place and it reflects everywhere.

import 'package:flutter/material.dart';

class AppColors {
  // ─── Private constructor ────────────────────────────────────────────────
  // This prevents anyone from doing `AppColors()` — it's purely a namespace
  AppColors._();

  // ─── Brand colors ────────────────────────────────────────────────────────
  // The signature LocoFly amber/yellow used on buttons, highlights, badges
  static const Color primary = Color(0xFFF5A623);
  static const Color primaryLight =
      Color(0xFFFFF3DC); // Very light amber background
  static const Color primaryDark =
      Color(0xFFCC8800); // Darker amber for pressed states

  // ─── Neutral / background ────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color background =
      Color(0xFFFAF8F3); // Warm off-white page background
  static const Color surface = Color(0xFFFFFFFF); // Card surfaces
  static const Color surfaceAlt = Color(0xFFF5F4F0); // Slightly darker surface

  // ─── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1C1C1E); // Near-black — main text
  static const Color textSecondary =
      Color(0xFF6B6B6B); // Gray — subtitles, hints
  static const Color textTertiary =
      Color(0xFFAAAAAA); // Light gray — placeholders

  // ─── Status colors ───────────────────────────────────────────────────────
  static const Color success =
      Color(0xFF34C759); // Green — "Available", bid accepted
  static const Color successLight = Color(0xFFEAF7EE);
  static const Color error =
      Color(0xFFFF3B30); // Red — "Sold Out", bid rejected
  static const Color errorLight = Color(0xFFFFF0EF);
  static const Color warning = Color(0xFFFF9500); // Orange — expiring bids
  static const Color warningLight = Color(0xFFFFF5E6);

  // ─── Border & divider ────────────────────────────────────────────────────
  static const Color border = Color(0xFFE8E8E8);
  static const Color divider = Color(0xFFF0F0F0);

  // ─── Specific UI elements (from Figma) ───────────────────────────────────
  static const Color darkButton =
      Color(0xFF1C1C1E); // The black "Login" / "Submit Bid" button
  static const Color inputBackground =
      Color(0xFFF8F8F8); // Search field background
  static const Color cardShadow =
      Color(0x0D000000); // Very subtle card shadow (5% black)

  // ─── Onboarding screen ───────────────────────────────────────────────────
  static const Color onboardingBackground =
      Color(0xFFF5A623); // Big yellow background
}
