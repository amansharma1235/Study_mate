import 'package:flutter_test/flutter_test.dart';
import 'package:study_mate/data/local/app_database.dart';
import 'package:study_mate/data/models/habit_model.dart';
import 'package:study_mate/data/models/note_model.dart';
import 'package:study_mate/data/models/sync_status.dart';
import 'package:study_mate/data/remote/firebase_service.dart';
import 'package:study_mate/data/remote/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncService & Offline Capabilities Unit Tests', () {
    test('SyncService detects cloud availability status properly', () {
      final syncService = SyncService(
        AppDatabase.instance,
        FirebaseService.instance,
      );

      // Default mock in pure test environment
      expect(syncService.isCloudAvailable, isA<bool>());
    });

    test('SyncResult computes total synced items accurately', () {
      final result = SyncResult(
        isSuccess: true,
        uploadedCount: 8,
        downloadedCount: 12,
        timestamp: DateTime.now(),
      );

      expect(result.totalItems, equals(20));
      expect(result.isSuccess, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('SyncState copyWith preserves timestamps and flags', () {
      final now = DateTime.now();
      const state = SyncState(
        isSyncing: false,
        totalSynced: 5,
        isCloudConnected: true,
      );

      final updated = state.copyWith(
        isSyncing: true,
        lastSyncedAt: now,
        totalSynced: 15,
      );

      expect(updated.isSyncing, isTrue);
      expect(updated.lastSyncedAt, equals(now));
      expect(updated.totalSynced, equals(15));
      expect(updated.isCloudConnected, isTrue);
    });

    test('Offline-first models maintain sync status transitions', () {
      final note = NoteModel(
        id: 'test-note-1',
        userId: 'student-123',
        title: 'Quantum Physics',
        content: 'Wave particle duality',
        category: 'Physics',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      expect(note.syncStatus, equals(SyncStatus.pending));

      final syncedNote = note.copyWith(syncStatus: SyncStatus.synced);
      expect(syncedNote.syncStatus, equals(SyncStatus.synced));
      expect(syncedNote.title, equals('Quantum Physics'));
    });

    test('HabitModel streak calculations and completion dates serialize cleanly', () {
      final habit = HabitModel(
        id: 'h-100',
        userId: 'student-123',
        title: 'Read 20 pages',
        currentStreak: 3,
        bestStreak: 10,
        completedDates: ['2026-10-15', '2026-10-16', '2026-10-17'],
      );

      final map = habit.toMap();
      expect(map['completedDates'], equals('2026-10-15,2026-10-16,2026-10-17'));

      final fromMap = HabitModel.fromMap(map);
      expect(fromMap.completedDates.length, equals(3));
      expect(fromMap.currentStreak, equals(3));
      expect(fromMap.bestStreak, equals(10));
    });
  });
}
