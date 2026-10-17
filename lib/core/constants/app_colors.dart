import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Master Mockup Palette (#6258E8 Indigo & #3987F5 Sky Blue)
  static const Color primary = Color(0xFF6258E8); // Master Royal Indigo
  static const Color primaryVariant = Color(0xFF4F46E5); // Deep Indigo
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFFEEF0FD); // Soft Lavender Glaze
  static const Color secondary = Color(0xFF3987F5); // Master Sky Blue / Azure
  static const Color secondaryLight = Color(0xFFEFF6FF);
  static const Color accentAmber = Color(0xFFF59E0B); // Golden Amber for streaks & achievements
  static const Color accentAmberLight = Color(0xFFFEF3C7);
  static const Color accentCyan = Color(0xFF06B6D4);

  // Backgrounds & Surfaces (Light - Clean Porcelain Slate #F7F7FC)
  static const Color backgroundLight = Color(0xFFF7F7FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5E7EB);

  // Backgrounds & Surfaces (Dark - #111827)
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color cardDark = Color(0xFF1F2937);
  static const Color borderDark = Color(0xFF374151);

  // Gradient Tokens - Vibrant Royal Iris to Sky Blue (From Master Design Mockup)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF6258E8), // Royal Iris Indigo
      Color(0xFF3987F5), // Vibrant Sky Blue
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [
      Color(0xFF6258E8), // Master Royal Iris
      Color(0xFF4C6EF5), // Luminous Royal Violet
      Color(0xFF3987F5), // Master Vibrant Sky Blue
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient electricCyanGradient = LinearGradient(
    colors: [
      Color(0xFF6258E8),
      Color(0xFF3987F5),
      Color(0xFF06B6D4),
    ],
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
