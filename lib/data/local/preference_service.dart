import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

final preferenceServiceProvider = Provider<PreferenceService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferenceService(prefs);
});

class PreferenceService {
  final SharedPreferences _prefs;

  PreferenceService(this._prefs);

  static const String _keyThemeMode = 'theme_mode';
  static const String _keyOnboardingDone = 'onboarding_done';
  static const String _keyDailyGoalMinutes = 'daily_goal_minutes';
  static const String _keyPomodoroFocusMinutes = 'pomodoro_focus_minutes';
  static const String _keyPomodoroShortBreakMinutes =
      'pomodoro_short_break_minutes';
  static const String _keyPomodoroLongBreakMinutes =
      'pomodoro_long_break_minutes';
  static const String _keyPomodoroSessionsBeforeLongBreak =
      'pomodoro_sessions_before_long_break';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keyNotificationsEnabled = 'notifications_enabled';

  // Theme
  ThemeMode getThemeMode() {
    final modeStr = _prefs.getString(_keyThemeMode);
    switch (modeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    await _prefs.setString(_keyThemeMode, val);
  }

  // Onboarding
  bool isOnboardingDone() => _prefs.getBool(_keyOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool done) =>
      _prefs.setBool(_keyOnboardingDone, done);

  // Daily Goal
  int getDailyGoalMinutes() => _prefs.getInt(_keyDailyGoalMinutes) ?? 120;
  Future<void> setDailyGoalMinutes(int mins) =>
      _prefs.setInt(_keyDailyGoalMinutes, mins);

  // Pomodoro Settings
  int getPomodoroFocusMinutes() =>
      _prefs.getInt(_keyPomodoroFocusMinutes) ?? 25;
  Future<void> setPomodoroFocusMinutes(int mins) =>
      _prefs.setInt(_keyPomodoroFocusMinutes, mins);

  int getPomodoroShortBreakMinutes() =>
      _prefs.getInt(_keyPomodoroShortBreakMinutes) ?? 5;
  Future<void> setPomodoroShortBreakMinutes(int mins) =>
      _prefs.setInt(_keyPomodoroShortBreakMinutes, mins);

  int getPomodoroLongBreakMinutes() =>
      _prefs.getInt(_keyPomodoroLongBreakMinutes) ?? 15;
  Future<void> setPomodoroLongBreakMinutes(int mins) =>
      _prefs.setInt(_keyPomodoroLongBreakMinutes, mins);

  int getSessionsBeforeLongBreak() =>
      _prefs.getInt(_keyPomodoroSessionsBeforeLongBreak) ?? 4;
  Future<void> setSessionsBeforeLongBreak(int count) =>
      _prefs.setInt(_keyPomodoroSessionsBeforeLongBreak, count);

  bool isSoundEnabled() => _prefs.getBool(_keySoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool enabled) =>
      _prefs.setBool(_keySoundEnabled, enabled);

  bool isVibrationEnabled() => _prefs.getBool(_keyVibrationEnabled) ?? true;
  Future<void> setVibrationEnabled(bool enabled) =>
      _prefs.setBool(_keyVibrationEnabled, enabled);

  bool isNotificationsEnabled() =>
      _prefs.getBool(_keyNotificationsEnabled) ?? true;
  Future<void> setNotificationsEnabled(bool enabled) =>
      _prefs.setBool(_keyNotificationsEnabled, enabled);
}
