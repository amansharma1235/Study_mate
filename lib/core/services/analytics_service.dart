import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight, privacy-respecting in-app analytics service.
/// Tracks educational engagement metrics without collecting PII (Personally Identifiable Information).
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  static const String _prefAnalyticsEnabled = 'pref_analytics_enabled';
  static const String _prefEventCounts = 'pref_analytics_event_counts';

  SharedPreferences? _prefs;
  bool _enabled = true;
  final Map<String, int> _sessionCounts = {};

  bool get isEnabled => _enabled;

  /// Initializes analytics with SharedPreferences.
  Future<void> init([SharedPreferences? prefs]) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
    _enabled = _prefs?.getBool(_prefAnalyticsEnabled) ?? true;
    _loadHistoricalCounts();
  }

  void _loadHistoricalCounts() {
    try {
      final jsonStr = _prefs?.getString(_prefEventCounts);
      if (jsonStr != null) {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        decoded.forEach((key, val) {
          if (val is int) _sessionCounts[key] = val;
        });
      }
    } catch (e) {
      debugPrint('Analytics load error: $e');
    }
  }

  /// Toggles whether analytical telemetry is recorded.
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await _prefs?.setBool(_prefAnalyticsEnabled, enabled);
  }

  /// Logs a custom academic event.
  void logEvent(String eventName, [Map<String, dynamic>? parameters]) {
    if (!_enabled) return;

    _sessionCounts[eventName] = (_sessionCounts[eventName] ?? 0) + 1;
    debugPrint('[Analytics] 📊 Event: $eventName ${parameters ?? ''}');

    // Persist event frequency
    _saveCounts();
  }

  /// Logs screen views for navigation tracking.
  void logScreenView(String screenName) {
    logEvent('screen_view', {'screen': screenName});
  }

  /// Helper events for student workflows
  void logStudySessionCompleted(int minutes, String mode) {
    logEvent('study_session_completed', {'duration_minutes': minutes, 'mode': mode});
  }

  void logTaskCompleted() {
    logEvent('task_completed');
  }

  void logNoteCreated() {
    logEvent('note_created');
  }

  void logAiQuery(String mode) {
    logEvent('ai_query_submitted', {'tutor_mode': mode});
  }

  void logFlashcardReviewed(int cardsCount) {
    logEvent('flashcard_reviewed', {'cards_count': cardsCount});
  }

  Map<String, int> getSummary() => Map.unmodifiable(_sessionCounts);

  Future<void> _saveCounts() async {
    try {
      await _prefs?.setString(_prefEventCounts, jsonEncode(_sessionCounts));
    } catch (_) {}
  }
}
