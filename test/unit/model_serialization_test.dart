import 'package:flutter_test/flutter_test.dart';
import 'package:study_mate/data/models/exam_model.dart';
import 'package:study_mate/data/models/note_model.dart';
import 'package:study_mate/data/models/sync_status.dart';
import 'package:study_mate/data/models/task_model.dart';

void main() {
  group('Model Serialization & Data Isolation Unit Tests', () {
    test('NoteModel serializes to and from map cleanly', () {
      final now = DateTime.now();
      final note = NoteModel(
        id: 'note-101',
        userId: 'user-xyz',
        title: 'Binary Search Trees',
        content: 'O(log n) average search complexity',
        category: 'Computer Science',
        isPinned: true,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.synced,
      );

      final map = note.toMap();
      expect(map['userId'], 'user-xyz');
      expect(map['isPinned'], 1);

      final reconstructed = NoteModel.fromMap(map);
      expect(reconstructed.id, note.id);
      expect(reconstructed.userId, note.userId);
      expect(reconstructed.isPinned, isTrue);
      expect(reconstructed.syncStatus, SyncStatus.synced);
    });

    test('TaskModel serializes priority and overdue conditions', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      final task = TaskModel(
        id: 'task-1',
        userId: 'student-42',
        title: 'Submit Lab Report',
        dueDate: pastDate,
        priority: TaskPriority.high,
        isCompleted: false,
        createdAt: pastDate,
        updatedAt: pastDate,
      );

      expect(task.isOverdue, isTrue);

      final map = task.toMap();
      expect(map['priority'], 'high');

      final reconstructed = TaskModel.fromMap(map);
      expect(reconstructed.priority, TaskPriority.high);
      expect(reconstructed.isOverdue, isTrue);
    });

    test('ExamModel handles past status and ISO date serialization', () {
      final futureDate = DateTime.now().add(const Duration(days: 10));
      final exam = ExamModel(
        id: 'exam-1',
        userId: 'student-42',
        title: 'Final Exam',
        subject: 'Networking',
        examDate: futureDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(exam.isPast, isFalse);

      final map = exam.toMap();
      final reconstructed = ExamModel.fromMap(map);
      expect(reconstructed.title, 'Final Exam');
      expect(reconstructed.isPast, isFalse);
    });
  });
}
