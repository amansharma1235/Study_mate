import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - StudyMate Official Palette (Azure Blue & Sunset Tangerine)
  static const Color primary = Color(0xFF1570EF); // Master Royal Azure Blue (Logo "Study")
  static const Color primaryVariant = Color(0xFF0E5CBD); // Deep Ocean Blue
  static const Color primaryDark = Color(0xFF0B4691);
  static const Color primaryLight = Color(0xFFEFF6FF); // Soft Cloud Azure
  
  static const Color secondary = Color(0xFFFF7A00); // Master Sunset Tangerine (Logo "Mate")
  static const Color secondaryVariant = Color(0xFFE06500);
  static const Color secondaryLight = Color(0xFFFFF7ED); // Warm Cream Glaze
  
  static const Color accentAmber = Color(0xFFFFB703); // Shining Golden Star
  static const Color accentAmberLight = Color(0xFFFEF3C7);
  static const Color accentCyan = Color(0xFF06B6D4); // Electric Cyan Spark

  // Backgrounds & Surfaces (Light - Clean Porcelain Slate #F8FAFC)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Backgrounds & Surfaces (Dark - True Midnight AMOLED #0B0E17)
  static const Color backgroundDark = Color(0xFF0B0E17);
  static const Color surfaceDark = Color(0xFF131826);
  static const Color cardDark = Color(0xFF181F32);
  static const Color borderDark = Color(0xFF242E46);

  // Gradient Tokens
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF1570EF), // Royal Azure
      Color(0xFF0284C7), // Vibrant Sky
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandDualGradient = LinearGradient(
    colors: [
      Color(0xFF1570EF), // Study Azure
      Color(0xFFFF7A00), // Mate Tangerine
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [
      Color(0xFF0F172A),
      Color(0xFF1E1B4B),
      Color(0xFF312E81),
      Color(0xFF4338CA),
    ],
    stops: [0.0, 0.35, 0.70, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient electricCyanGradient = LinearGradient(
    colors: [
      Color(0xFF1570EF),
      Color(0xFF06B6D4),
      Color(0xFF10B981),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient midnightCardGradient = LinearGradient(
    colors: [
      Color(0xFF1A2238),
      Color(0xFF121727),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Typography Tokens
  static const Color textPrimaryLight = Color(0xFF0F172A); // Deep Slate
  static const Color textSecondaryLight = Color(0xFF475569); // Muted Slate
  static const Color textMutedLight = Color(0xFF94A3B8);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0284C7);
  static const Color infoLight = Color(0xFFE0F2FE);

  // Subject Palette for Timetable & Categorization
  static const List<Color> subjectPalette = [
    Color(0xFF1570EF), // Azure Blue
    Color(0xFFFF7A00), // Tangerine
    Color(0xFF10B981), // Emerald
    Color(0xFF8B5CF6), // Royal Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF43F5E), // Rose Coral
    Color(0xFFFFB703), // Golden Amber
    Color(0xFF6366F1), // Indigo
  ];
}
