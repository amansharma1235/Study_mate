import 'package:flutter_test/flutter_test.dart';
import 'package:study_mate/data/models/flashcard_model.dart';
import 'package:study_mate/data/models/habit_model.dart';
import 'package:study_mate/data/models/planner_model.dart';

void main() {
  group('Smart Planner Time Conflict Detection Tests', () {
    final date = DateTime(2026, 10, 20);

    test('Detects overlapping sessions on same day', () {
      final sessionA = StudySessionModel(
        id: '1',
        userId: 'u1',
        subject: 'Math',
        topic: 'Calculus',
        sessionDate: date,
        startTime: '09:00',
        endTime: '10:30',
        durationMinutes: 90,
      );

      final sessionB = StudySessionModel(
        id: '2',
        userId: 'u1',
        subject: 'Physics',
        topic: 'Mechanics',
        sessionDate: date,
        startTime: '10:00', // overlaps with 09:00 - 10:30
        endTime: '11:00',
        durationMinutes: 60,
      );

      expect(StudySessionModel.hasTimeConflict(sessionA, sessionB), isTrue);
    });

    test('Allows non-overlapping consecutive sessions on same day', () {
      final sessionA = StudySessionModel(
        id: '1',
        userId: 'u1',
        subject: 'Math',
        topic: 'Calculus',
        sessionDate: date,
        startTime: '09:00',
        endTime: '10:00',
        durationMinutes: 60,
      );

      final sessionB = StudySessionModel(
        id: '2',
        userId: 'u1',
        subject: 'Physics',
        topic: 'Mechanics',
        sessionDate: date,
        startTime: '10:00',
        endTime: '11:00',
        durationMinutes: 60,
      );

      expect(StudySessionModel.hasTimeConflict(sessionA, sessionB), isFalse);
    });

    test('Allows overlapping hours if dates are different', () {
      final sessionA = StudySessionModel(
        id: '1',
        userId: 'u1',
        subject: 'Math',
        topic: 'Calculus',
        sessionDate: date,
        startTime: '09:00',
        endTime: '10:30',
        durationMinutes: 90,
      );

      final sessionB = StudySessionModel(
        id: '2',
        userId: 'u1',
        subject: 'Physics',
        topic: 'Mechanics',
        sessionDate: date.add(const Duration(days: 1)),
        startTime: '09:00',
        endTime: '10:30',
        durationMinutes: 90,
      );

      expect(StudySessionModel.hasTimeConflict(sessionA, sessionB), isFalse);
    });
  });

  group('SuperMemo SM-2 Spaced Repetition Algorithm Tests', () {
    test('Again resets repetition number and interval to 1 day', () {
      final card = FlashcardModel(
        id: 'c1',
        deckId: 'd1',
        userId: 'u1',
        front: 'Q',
        back: 'A',
        repetitionNumber: 3,
        intervalDays: 14,
        easeFactor: 2.5,
      );

      final reviewed = card.review(CardRating.again);
      expect(reviewed.repetitionNumber, equals(0));
      expect(reviewed.intervalDays, equals(1));
      expect(reviewed.easeFactor, lessThan(2.5));
    });

    test('Good increments repetition number and increases interval', () {
      final card = FlashcardModel(
        id: 'c1',
        deckId: 'd1',
        userId: 'u1',
        front: 'Q',
        back: 'A',
        repetitionNumber: 0,
        intervalDays: 0,
        easeFactor: 2.5,
      );

      final firstReview = card.review(CardRating.good);
      expect(firstReview.repetitionNumber, equals(1));
      expect(firstReview.intervalDays, equals(1));

      final secondReview = firstReview.review(CardRating.good);
      expect(secondReview.repetitionNumber, equals(2));
      expect(secondReview.intervalDays, equals(6));

      final thirdReview = secondReview.review(CardRating.good);
      expect(thirdReview.repetitionNumber, equals(3));
      expect(thirdReview.intervalDays, greaterThanOrEqualTo(15));
    });
  });

  group('Habits Streak and Toggle Tests', () {
    test('Toggling habit today increases streak and marks date', () {
      final habit = HabitModel(
        id: 'h1',
        userId: 'u1',
        title: 'Revise notes',
        currentStreak: 2,
        bestStreak: 5,
        completedDates: [],
      );

      expect(habit.isCompletedToday(), isFalse);

      final toggled = habit.toggleToday();
      expect(toggled.isCompletedToday(), isTrue);
      expect(toggled.currentStreak, equals(3));

      final untoggled = toggled.toggleToday();
      expect(untoggled.isCompletedToday(), isFalse);
      expect(untoggled.currentStreak, equals(2));
    });
  });
}
