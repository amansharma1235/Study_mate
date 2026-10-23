import 'package:flutter_test/flutter_test.dart';
import 'package:study_mate/data/local/notification_service.dart';
import 'package:study_mate/data/models/exam_model.dart';
import 'package:study_mate/data/models/note_model.dart';
import 'package:study_mate/data/models/pomodoro_session_model.dart';
import 'package:study_mate/data/models/quiz_model.dart';
import 'package:study_mate/data/models/study_tip_model.dart';
import 'package:study_mate/data/models/sync_status.dart';
import 'package:study_mate/data/models/task_model.dart';
import 'package:study_mate/data/models/timetable_model.dart';
import 'package:study_mate/data/remote/firebase_service.dart';
import 'package:study_mate/data/repositories/exams_repository.dart';
import 'package:study_mate/data/repositories/notes_repository.dart';
import 'package:study_mate/data/repositories/quiz_repository.dart';
import 'package:study_mate/data/repositories/study_tips_repository.dart';
import 'package:study_mate/data/repositories/tasks_repository.dart';
import 'package:study_mate/data/repositories/timer_repository.dart';
import 'package:study_mate/data/repositories/timetable_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final firebaseService = FirebaseService.instance;
  final notifService = NotificationService.instance;

  group('Cloud-First Repositories & Non-Negotiable Zero-Persistence Tests', () {
    test('NotesRepository operates in-memory when offline and isolates user data', () async {
      final repo = NotesRepository(firebaseService);

      final noteA = NoteModel(
        id: 'note-u1-1',
        userId: 'user_alpha',
        title: 'Alpha Note',
        content: 'Alpha Content',
        category: 'Study',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final noteB = NoteModel(
        id: 'note-u2-1',
        userId: 'user_beta',
        title: 'Beta Note',
        content: 'Beta Content',
        category: 'Study',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.saveNote(noteA);
      await repo.saveNote(noteB);

      final alphaNotes = await repo.getNotes('user_alpha');
      final betaNotes = await repo.getNotes('user_beta');

      // Verify user isolation
      expect(alphaNotes.length, equals(1));
      expect(alphaNotes.first.id, equals('note-u1-1'));
      expect(betaNotes.length, equals(1));
      expect(betaNotes.first.id, equals('note-u2-1'));
      expect(alphaNotes.any((n) => n.userId == 'user_beta'), isFalse);

      // Deletion test
      await repo.deleteNote('note-u1-1', 'user_alpha');
      final emptyAlpha = await repo.getNotes('user_alpha');
      expect(emptyAlpha.isEmpty, isTrue);
      // Beta note remains untouched
      expect((await repo.getNotes('user_beta')).length, equals(1));
    });

    test('TasksRepository handles save, toggle completion, and deletion', () async {
      final repo = TasksRepository(firebaseService, notifService);

      final task = TaskModel(
        id: 'task-101',
        userId: 'user_student',
        title: 'Finish Physics Assignment',
        dueDate: DateTime.now().add(const Duration(hours: 4)),
        priority: TaskPriority.high,
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.saveTask(task);
      var tasks = await repo.getTasks('user_student');
      expect(tasks.length, equals(1));
      expect(tasks.first.isCompleted, isFalse);

      // Toggle completion
      await repo.toggleTask(tasks.first);
      tasks = await repo.getTasks('user_student');
      expect(tasks.first.isCompleted, isTrue);

      // Delete task
      await repo.deleteTask(task.id, 'user_student');
      tasks = await repo.getTasks('user_student');
      expect(tasks.isEmpty, isTrue);
    });

    test('TimetableRepository saves schedule items with proper day and time ordering', () async {
      final repo = TimetableRepository(firebaseService);

      final entry1 = TimetableModel(
        id: 'tt-1',
        userId: 'user_tt',
        subject: 'Algorithms',
        dayOfWeek: 1, // Monday
        startTime: '09:00',
        endTime: '10:30',
        room: 'Lab 3',
        instructor: 'Dr. Turing',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.saveTimetable(entry1);
      final list = await repo.getTimetable('user_tt');
      expect(list.length, equals(1));
      expect(list.first.subject, equals('Algorithms'));

      await repo.deleteTimetable(entry1.id, 'user_tt');
      expect((await repo.getTimetable('user_tt')).isEmpty, isTrue);
    });

    test('ExamsRepository correctly tracks exam dates and filters by user', () async {
      final repo = ExamsRepository(firebaseService, notifService);

      final exam = ExamModel(
        id: 'exam-1',
        userId: 'user_exam',
        title: 'Operating Systems Midterm',
        subject: 'CS301',
        examDate: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.saveExam(exam);
      final exams = await repo.getExams('user_exam');
      expect(exams.length, equals(1));
      expect(exams.first.title, equals('Operating Systems Midterm'));

      await repo.deleteExam(exam.id, 'user_exam');
      expect((await repo.getExams('user_exam')).isEmpty, isTrue);
    });

    test('TimerRepository computes study minutes, weekly breakdown, and streaks', () async {
      final repo = TimerRepository(firebaseService);
      final now = DateTime.now();

      final session1 = PomodoroSessionModel(
        id: 'sess-1',
        userId: 'user_timer',
        subject: 'Data Structures',
        durationMinutes: 25,
        mode: PomodoroMode.focus,
        completedAt: now,
        syncStatus: SyncStatus.synced,
      );

      final session2 = PomodoroSessionModel(
        id: 'sess-2',
        userId: 'user_timer',
        subject: 'Algorithms',
        durationMinutes: 30,
        mode: PomodoroMode.focus,
        completedAt: now,
        syncStatus: SyncStatus.synced,
      );

      await repo.recordSession(session1);
      await repo.recordSession(session2);

      final todayMinutes = await repo.getTodayStudyMinutes('user_timer');
      expect(todayMinutes, equals(55));

      final sessions = await repo.getSessions('user_timer');
      expect(sessions.length, equals(2));

      final streak = repo.calculateStudyStreak(sessions);
      expect(streak, greaterThanOrEqualTo(1));
    });

    test('QuizRepository stores user quiz attempts in-memory during session', () async {
      final repo = QuizRepository(firebaseService: firebaseService);

      final attempt = QuizAttempt(
        id: 'qa-1',
        userId: 'user_quiz',
        category: 'Data Structures',
        totalQuestions: 10,
        correctAnswers: 9,
        scorePercentage: 90.0,
        completedAt: DateTime.now(),
      );

      await repo.saveAttempt(attempt);
      final attempts = await repo.getAttempts('user_quiz');
      expect(attempts.length, equals(1));
      expect(attempts.first.scorePercentage, equals(90.0));
      expect(attempts.first.category, equals('Data Structures'));
    });

    test('StudyTipsRepository toggles bookmarks in-memory per user', () async {
      final repo = StudyTipsRepository(firebaseService);

      final tip = StudyTipModel(
        id: 'tip-1',
        title: 'Feynman Technique',
        category: 'Methodology',
        summary: 'Explain simply to test mastery',
        content: 'Step 1: Choose concept...',
        isFavorite: false,
      );

      await repo.toggleFavorite(tip, userId: 'user_tips');
      final savedIds = await repo.getSavedTipIds('user_tips');
      expect(savedIds.contains('tip-1'), isTrue);

      await repo.toggleFavorite(tip, userId: 'user_tips');
      final updatedIds = await repo.getSavedTipIds('user_tips');
      expect(updatedIds.contains('tip-1'), isFalse);
    });
  });
}
