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
  static const String _keyAccentTheme = 'accent_theme';

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

  String getAccentTheme() {
    return _prefs.getString(_keyAccentTheme) ?? 'studyMate';
  }

  Future<void> setAccentTheme(String accentKey) async {
    await _prefs.setString(_keyAccentTheme, accentKey);
  }

  // Onboarding
  static const String _keyNewOnboardingSeen = 'new_onboarding_seen_v2';
  bool isOnboardingDone() => _prefs.getBool(_keyOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool done) =>
      _prefs.setBool(_keyOnboardingDone, done);
  bool hasSeenNewOnboarding() => _prefs.getBool(_keyNewOnboardingSeen) ?? false;
  Future<void> setHasSeenNewOnboarding(bool seen) =>
      _prefs.setBool(_keyNewOnboardingSeen, seen);

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

  // Gemini API Key
  static const String _keyGeminiApiKey = 'user_gemini_api_key';
  String getGeminiApiKey() => _prefs.getString(_keyGeminiApiKey) ?? '';
  Future<void> setGeminiApiKey(String key) =>
      _prefs.setString(_keyGeminiApiKey, key.trim());

  // Gamification & XP
  static const String _keyUserXp = 'gamification_user_xp';
  static const String _keyTasksCompletedXp = 'gamification_tasks_completed_count';
  static const String _keyPomodoroCompletedXp = 'gamification_pomodoro_completed_count';
  static const String _keyStudyCoins = 'gamification_study_coins';
  static const String _keyUnlockedTrees = 'gamification_unlocked_trees';
  static const String _keySelectedTree = 'gamification_selected_tree';
  static const String _keyPlantedTrees = 'gamification_planted_trees_v1';

  int getUserXp() => _prefs.getInt(_keyUserXp) ?? 50; // Starter scholarship 50 XP
  Future<void> setUserXp(int xp) => _prefs.setInt(_keyUserXp, xp);

  int getCompletedTasksCount() => _prefs.getInt(_keyTasksCompletedXp) ?? 0;
  Future<void> incrementCompletedTasksCount() =>
      _prefs.setInt(_keyTasksCompletedXp, getCompletedTasksCount() + 1);

  int getCompletedPomodoroCount() => _prefs.getInt(_keyPomodoroCompletedXp) ?? 0;
  Future<void> incrementCompletedPomodoroCount() =>
      _prefs.setInt(_keyPomodoroCompletedXp, getCompletedPomodoroCount() + 1);

  // Study Coins
  int getStudyCoins() => _prefs.getInt(_keyStudyCoins) ?? 50; // 50 coins starter bonus
  Future<void> setStudyCoins(int coins) => _prefs.setInt(_keyStudyCoins, coins);
  Future<void> addStudyCoins(int amount) => setStudyCoins(getStudyCoins() + amount);

  // Virtual Garden Trees
  List<String> getUnlockedTreeIds() {
    return _prefs.getStringList(_keyUnlockedTrees) ?? ['bonsai_sprout'];
  }

  Future<void> unlockTreeId(String treeId) async {
    final current = getUnlockedTreeIds().toSet();
    current.add(treeId);
    await _prefs.setStringList(_keyUnlockedTrees, current.toList());
  }

  String getSelectedTreeId() => _prefs.getString(_keySelectedTree) ?? 'bonsai_sprout';
  Future<void> setSelectedTreeId(String treeId) =>
      _prefs.setString(_keySelectedTree, treeId);

  List<String> getPlantedTreesJsonList() =>
      _prefs.getStringList(_keyPlantedTrees) ?? [];

  Future<void> addPlantedTreeRecord(String treeRecordJson) async {
    final list = List<String>.from(getPlantedTreesJsonList());
    list.add(treeRecordJson);
    await _prefs.setStringList(_keyPlantedTrees, list);
  }

  // App Lock & Privacy
  static const String _keyAppLockEnabled = 'security_app_lock_enabled';
  static const String _keyAppLockPin = 'security_app_lock_pin';
  static const String _keyBiometricsEnabled = 'security_biometrics_enabled';

  bool isAppLockEnabled() => _prefs.getBool(_keyAppLockEnabled) ?? false;
  Future<void> setAppLockEnabled(bool enabled) =>
      _prefs.setBool(_keyAppLockEnabled, enabled);

  String getAppLockPin() => _prefs.getString(_keyAppLockPin) ?? '';
  Future<void> setAppLockPin(String pin) =>
      _prefs.setString(_keyAppLockPin, pin);

  bool isBiometricsEnabled() => _prefs.getBool(_keyBiometricsEnabled) ?? false;
  Future<void> setBiometricsEnabled(bool enabled) =>
      _prefs.setBool(_keyBiometricsEnabled, enabled);

  // Strict Focus Mode (Anti-distraction Forest style)
  static const String _keyStrictMode = 'timer_strict_focus_mode';
  bool isStrictMode() => _prefs.getBool(_keyStrictMode) ?? false;
  Future<void> setStrictMode(bool enabled) =>
      _prefs.setBool(_keyStrictMode, enabled);
}

