import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';
import '../../data/models/planner_model.dart';
import '../auth/auth_controller.dart';
import '../exams/exams_controller.dart';

final selectedPlannerDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final plannerControllerProvider =
    StateNotifierProvider<
      PlannerController,
      AsyncValue<List<StudySessionModel>>
    >((ref) {
      final db = ref.watch(appDatabaseProvider);
      final user = ref.watch(currentProfileProvider);
      final userId = user?.uid ?? 'guest';
      return PlannerController(db, userId, ref);
    });

final dailySessionsProvider = Provider<List<StudySessionModel>>((ref) {
  final sessionsAsync = ref.watch(plannerControllerProvider);
  final selectedDate = ref.watch(selectedPlannerDateProvider);

  return sessionsAsync.maybeWhen(
    data: (sessions) {
      return sessions.where((s) {
        return s.sessionDate.year == selectedDate.year &&
            s.sessionDate.month == selectedDate.month &&
            s.sessionDate.day == selectedDate.day;
      }).toList();
    },
    orElse: () => [],
  );
});

class PlannerController
    extends StateNotifier<AsyncValue<List<StudySessionModel>>> {
  final AppDatabase _db;
  final String _userId;
  final Ref _ref;

  PlannerController(this._db, this._userId, this._ref)
    : super(const AsyncValue.loading()) {
    loadSessions();
  }

  Future<void> loadSessions() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () async => await _db.getStudySessions(_userId),
    );
  }

  Future<void> addSession({
    required String subject,
    required String topic,
    required DateTime sessionDate,
    required String startTime,
    required String endTime,
    int durationMinutes = 60,
    String priority = 'medium',
    String difficulty = 'medium',
    bool isBreak = false,
    String notes = '',
  }) async {
    final session = StudySessionModel(
      id: const Uuid().v4(),
      userId: _userId,
      subject: subject,
      topic: topic,
      sessionDate: sessionDate,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      priority: priority,
      difficulty: difficulty,
      isBreak: isBreak,
      notes: notes,
    );

    await _db.insertStudySession(session);
    await loadSessions();
  }

  Future<void> toggleComplete(StudySessionModel session) async {
    final updated = session.copyWith(isCompleted: !session.isCompleted);
    await _db.updateStudySession(updated);
    await loadSessions();
  }

  Future<void> deleteSession(String id) async {
    await _db.deleteStudySession(id);
    await loadSessions();
  }

  // Automatic Intelligent Schedule Generation based on Upcoming Exams & Priority
  Future<int> autoGenerateSchedule({
    required DateTime startDate,
    required int dailyStudyHours,
    required int sessionLengthMinutes,
  }) async {
    final examsState = _ref.read(examsControllerProvider);
    final exams = examsState.maybeWhen(data: (list) => list, orElse: () => []);

    if (exams.isEmpty) {
      // Create standard balanced schedule for 5 core subjects
      final sampleSubjects = [
        'Mathematics',
        'Physics',
        'Computer Science',
        'English',
        'Chemistry',
      ];
      int created = 0;
      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final currentDate = startDate.add(Duration(days: dayOffset));
        final subject = sampleSubjects[dayOffset % sampleSubjects.length];

        await addSession(
          subject: subject,
          topic: 'Chapter Review & Practice Exercises',
          sessionDate: currentDate,
          startTime: '09:00',
          endTime: '10:30',
          durationMinutes: 90,
          priority: 'high',
          difficulty: 'medium',
        );

        // Add 15 min break
        await addSession(
          subject: 'Break',
          topic: 'Healthy Rest & Hydration',
          sessionDate: currentDate,
          startTime: '10:30',
          endTime: '10:45',
          durationMinutes: 15,
          isBreak: true,
        );

        // Session 2
        final subject2 =
            sampleSubjects[(dayOffset + 1) % sampleSubjects.length];
        await addSession(
          subject: subject2,
          topic: 'Important Concepts & Problem Solving',
          sessionDate: currentDate,
          startTime: '10:45',
          endTime: '12:15',
          durationMinutes: 90,
          priority: 'medium',
          difficulty: 'hard',
        );
        created += 3;
      }
      return created;
    }

    // Schedule prioritized by exam proximity
    final sortedExams = List.of(exams)
      ..sort((a, b) => a.examDate.compareTo(b.examDate));
    int createdCount = 0;

    for (int day = 0; day < 5; day++) {
      final planDate = startDate.add(Duration(days: day));
      final exam = sortedExams[day % sortedExams.length];
      final daysLeft = exam.examDate.difference(planDate).inDays;
      final priority = daysLeft <= 3
          ? 'urgent'
          : (daysLeft <= 7 ? 'high' : 'medium');

      await addSession(
        subject: exam.subject,
        topic: '${exam.title} - High Weightage Revision',
        sessionDate: planDate,
        startTime: '14:00',
        endTime: '15:30',
        durationMinutes: 90,
        priority: priority,
        difficulty: 'hard',
        notes: 'Exam in $daysLeft days. Focus on previous year questions.',
      );
      createdCount++;
    }

    return createdCount;
  }
}
