import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF6258E8);
  static const Color primaryVariant = Color(0xFF4C42D0);
  static const Color primaryLight = Color(0xFFEBE9FC);
  static const Color secondary = Color(0xFF3987F5);
  static const Color secondaryLight = Color(0xFFE7F0FE);

  // Backgrounds & Surfaces (Light)
  static const Color backgroundLight = Color(0xFFF7F7FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E4F0);

  // Backgrounds & Surfaces (Dark)
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color cardDark = Color(0xFF1F2937);
  static const Color borderDark = Color(0xFF374151);

  // Gradient Tokens
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Typography
  static const Color textPrimaryLight = Color(0xFF1E2134);
  static const Color textSecondaryLight = Color(0xFF6E748E);
  static const Color textMutedLight = Color(0xFFA1A7C4);

  static const Color textPrimaryDark = Color(0xFFF3F4FB);
  static const Color textSecondaryDark = Color(0xFFA1A7C4);
  static const Color textMutedDark = Color(0xFF6E748E);

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF06B6D4);
  static const Color infoLight = Color(0xFFCFFAFE);

  // Subject Palette for Timetable & Categorization
  static const List<Color> subjectPalette = [
    Color(0xFF6258E8), // Indigo
    Color(0xFF3987F5), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
  ];
}
