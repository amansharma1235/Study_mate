import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pomodoro_session_model.dart';
import '../models/sync_status.dart';
import '../remote/firebase_service.dart';

final timerRepositoryProvider = Provider<TimerRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return TimerRepository(firebaseService);
});

/// Pure Cloud-First Timer Repository.
/// All completed study focus sessions are written to Cloud Firestore (users/{userId}/pomodoro_sessions).
/// In-memory state is maintained temporarily during execution.
/// No session logs are persisted locally in SQLite or local files.
class TimerRepository {
  final FirebaseService _firebaseService;
  final Map<String, List<PomodoroSessionModel>> _sessionCache = {};

  TimerRepository(this._firebaseService);

  Future<List<PomodoroSessionModel>> getSessions(String userId) async {
    if (userId.isEmpty) return [];

    if (_firebaseService.isConfigured && userId != 'guest') {
      try {
        final col = _firebaseService.getUserCollection(
          userId,
          'pomodoro_sessions',
        );
        if (col != null) {
          final snapshot = await col
              .orderBy('completedAt', descending: true)
              .get();
          final sessions = snapshot.docs
              .map((doc) => PomodoroSessionModel.fromMap(doc.data()))
              .toList();
          _sessionCache[userId] = sessions;
          return sessions;
        }
      } catch (e) {
        debugPrint('Cloud timer sessions fetch notice: $e');
        return _sessionCache[userId] ?? [];
      }
    }

    return _sessionCache[userId] ?? [];
  }

  Future<void> recordSession(PomodoroSessionModel session) async {
    final sessionWithSync = session.copyWith(syncStatus: SyncStatus.synced);

    final list = _sessionCache[session.userId] ?? [];
    list.insert(0, sessionWithSync);
    _sessionCache[session.userId] = list;

    if (_firebaseService.isConfigured &&
        session.userId.isNotEmpty &&
        session.userId != 'guest') {
      final col = _firebaseService.getUserCollection(
        session.userId,
        'pomodoro_sessions',
      );
      if (col != null) {
        await col.doc(session.id).set(sessionWithSync.toFirestoreMap());
      }
    }
  }

  Future<int> getTodayStudyMinutes(String userId) async {
    final sessions = await getSessions(userId);
    final now = DateTime.now();

    return sessions
        .where(
          (s) =>
              s.mode == PomodoroMode.focus &&
              s.completedAt.year == now.year &&
              s.completedAt.month == now.month &&
              s.completedAt.day == now.day,
        )
        .fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  Future<Map<int, int>> getWeeklyStudyMinutes(String userId) async {
    final sessions = await getSessions(userId);
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);

    final Map<int, int> weeklyMinutes = {
      1: 0,
      2: 0,
      3: 0,
      4: 0,
      5: 0,
      6: 0,
      7: 0,
    };

    for (final s in sessions) {
      if (s.mode == PomodoroMode.focus && s.completedAt.isAfter(startOfWeek)) {
        final weekday = s.completedAt.weekday;
        weeklyMinutes[weekday] =
            ((weeklyMinutes[weekday] ?? 0) + s.durationMinutes).toInt();
      }
    }

    return weeklyMinutes;
  }

  int calculateStudyStreak(List<PomodoroSessionModel> sessions) {
    if (sessions.isEmpty) return 0;

    final focusSessions = sessions
        .where((s) => s.mode == PomodoroMode.focus)
        .toList();
    if (focusSessions.isEmpty) return 0;

    final dates =
        focusSessions
            .map(
              (s) => DateTime(
                s.completedAt.year,
                s.completedAt.month,
                s.completedAt.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (!dates.contains(today) && !dates.contains(yesterday)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = dates.contains(today) ? today : yesterday;

    while (dates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }
}
