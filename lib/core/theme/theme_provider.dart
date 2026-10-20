import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/preference_service.dart';

enum AccentTheme {
  studyMate,
  cyberpunk,
  emerald,
  sunset;

  String get displayName {
    switch (this) {
      case AccentTheme.studyMate:
        return 'StudyMate Signature';
      case AccentTheme.cyberpunk:
        return 'Cyberpunk Aurora';
      case AccentTheme.emerald:
        return 'Forest Focus';
      case AccentTheme.sunset:
        return 'Sunset Amber';
    }
  }

  String get subtitle {
    switch (this) {
      case AccentTheme.studyMate:
        return 'Official brand: Royal Azure Blue & Sunset Tangerine';
      case AccentTheme.cyberpunk:
        return 'Modern energy: Royal Indigo & Neon Violet';
      case AccentTheme.emerald:
        return 'Calm productivity: Deep Emerald & Sea Cyan';
      case AccentTheme.sunset:
        return 'Warm motivation: Vibrant Tangerine & Coral Rose';
    }
  }

  Color get primaryColor {
    switch (this) {
      case AccentTheme.studyMate:
        return const Color(0xFF1570EF); // Azure Blue
      case AccentTheme.cyberpunk:
        return const Color(0xFF6366F1); // Indigo
      case AccentTheme.emerald:
        return const Color(0xFF10B981); // Emerald
      case AccentTheme.sunset:
        return const Color(0xFFF97316); // Tangerine
    }
  }

  Color get secondaryColor {
    switch (this) {
      case AccentTheme.studyMate:
        return const Color(0xFFFF7A00); // Tangerine
      case AccentTheme.cyberpunk:
        return const Color(0xFFA855F7); // Violet
      case AccentTheme.emerald:
        return const Color(0xFF06B6D4); // Cyan
      case AccentTheme.sunset:
        return const Color(0xFFF43F5E); // Rose
    }
  }

  LinearGradient get gradient {
    return LinearGradient(
      colors: [primaryColor, secondaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final prefs = ref.watch(preferenceServiceProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final PreferenceService _preferenceService;

  ThemeModeNotifier(this._preferenceService)
      : super(_preferenceService.getThemeMode());

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _preferenceService.setThemeMode(mode);
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}

final accentThemeProvider =
    StateNotifierProvider<AccentThemeNotifier, AccentTheme>((ref) {
  final prefs = ref.watch(preferenceServiceProvider);
  return AccentThemeNotifier(prefs);
});

class AccentThemeNotifier extends StateNotifier<AccentTheme> {
  final PreferenceService _preferenceService;

  AccentThemeNotifier(this._preferenceService)
      : super(_loadInitial(_preferenceService));

  static AccentTheme _loadInitial(PreferenceService prefs) {
    final key = prefs.getAccentTheme();
    return AccentTheme.values.firstWhere(
      (e) => e.name == key,
      orElse: () => AccentTheme.studyMate,
    );
  }

  Future<void> setAccentTheme(AccentTheme accent) async {
    state = accent;
    await _preferenceService.setAccentTheme(accent.name);
  }
}
