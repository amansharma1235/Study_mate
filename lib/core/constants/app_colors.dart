import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Signature Astral Blue & Electric Sapphire (Unique Modern Palette)
  static const Color primary = Color(0xFF2563EB); // Electric Royal Blue
  static const Color primaryVariant = Color(0xFF1D4ED8); // Deep Royal Navy
  static const Color primaryDark = Color(0xFF0F172A); // Midnight Slate
  static const Color primaryLight = Color(0xFFEFF6FF); // Soft Glacial Ice
  static const Color secondary = Color(0xFF0891B2); // Deep Cyan
  static const Color secondaryLight = Color(0xFFECFEFF);
  static const Color accentAmber = Color(0xFFF59E0B); // Golden Amber for streaks & achievements
  static const Color accentAmberLight = Color(0xFFFEF3C7);
  static const Color accentCyan = Color(0xFF06B6D4); // Electric Cyan highlight

  // Backgrounds & Surfaces (Light)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Backgrounds & Surfaces (Dark)
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF131B2E);
  static const Color cardDark = Color(0xFF131B2E);
  static const Color borderDark = Color(0xFF1E293B);

  // Gradient Tokens - Deep Astral Midnight to Electric Royal Blue
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF0F172A), // Midnight Obsidian
      Color(0xFF1E3A8A), // Deep Sapphire
      Color(0xFF2563EB), // Electric Royal Azure
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [
      Color(0xFF0B132B), // Deep Midnight
      Color(0xFF1C3166), // Rich Indigo-Navy
      Color(0xFF2563EB), // Radiant Royal Blue
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient electricCyanGradient = LinearGradient(
    colors: [
      Color(0xFF1E3A8A),
      Color(0xFF0284C7),
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
