import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_database.dart';
import '../models/pomodoro_session_model.dart';
import '../models/sync_status.dart';
import '../remote/firebase_service.dart';

final timerRepositoryProvider = Provider<TimerRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  return TimerRepository(db, firebaseService);
});

class TimerRepository {
  final AppDatabase _db;
  final FirebaseService _firebaseService;

  TimerRepository(this._db, this._firebaseService);

  Future<List<PomodoroSessionModel>> getSessions(String userId) async {
    final localSessions = await _db.getSessions(userId);

    if (_firebaseService.isConfigured && userId.isNotEmpty) {
      _syncFromRemote(userId).catchError((e) {
        debugPrint('Timer sessions sync notice: $e');
        return <PomodoroSessionModel>[];
      });
    }

    return localSessions;
  }

  Future<void> recordSession(PomodoroSessionModel session) async {
    await _db.insertSession(session);

    if (_firebaseService.isConfigured && session.userId.isNotEmpty) {
      try {
        final col = _firebaseService.getUserCollection(
          session.userId,
          'pomodoro_sessions',
        );
        if (col != null) {
          await col.doc(session.id).set(session.toFirestoreMap());
        }
      } catch (e) {
        debugPrint('Firestore timer session record warning: $e');
      }
    }
  }

  Future<int> getTodayStudyMinutes(String userId) async {
    final sessions = await _db.getSessions(userId);
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
    // Maps dayOfWeek (1=Mon..7=Sun) to total focus minutes
    final sessions = await _db.getSessions(userId);
    final now = DateTime.now();
    // Monday of current week
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

  Future<List<PomodoroSessionModel>> _syncFromRemote(String userId) async {
    final col = _firebaseService.getUserCollection(userId, 'pomodoro_sessions');
    if (col == null) return [];

    final snapshot = await col.get();
    final remoteSessions = snapshot.docs
        .map((doc) => PomodoroSessionModel.fromMap(doc.data()))
        .toList();

    for (final session in remoteSessions) {
      await _db.insertSession(session.copyWith(syncStatus: SyncStatus.synced));
    }
    return remoteSessions;
  }
}
