import 'package:flutter_test/flutter_test.dart';
import 'package:study_mate/data/models/timetable_model.dart';

void main() {
  group('Timetable Conflict Detection Unit Tests', () {
    final entry1 = TimetableModel(
      id: 'entry-1',
      userId: 'user-1',
      subject: 'Algorithms',
      dayOfWeek: 1, // Monday
      startTime: '09:00',
      endTime: '10:30',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('Detects overlapping time on same day', () {
      final overlapping = TimetableModel(
        id: 'entry-2',
        userId: 'user-1',
        subject: 'Database Systems',
        dayOfWeek: 1, // Monday
        startTime: '10:00',
        endTime: '11:30',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(entry1.hasConflictWith(overlapping), isTrue);
    });

    test('Allows non-overlapping class on same day', () {
      final nonOverlapping = TimetableModel(
        id: 'entry-3',
        userId: 'user-1',
        subject: 'Operating Systems',
        dayOfWeek: 1, // Monday
        startTime: '10:30',
        endTime: '12:00',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(entry1.hasConflictWith(nonOverlapping), isFalse);
    });

    test('Allows overlapping time on different day', () {
      final differentDay = TimetableModel(
        id: 'entry-4',
        userId: 'user-1',
        subject: 'Linear Algebra',
        dayOfWeek: 2, // Tuesday
        startTime: '09:30',
        endTime: '11:00',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(entry1.hasConflictWith(differentDay), isFalse);
    });
  });
}
