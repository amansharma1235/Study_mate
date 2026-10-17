import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_database.dart';
import '../models/exam_model.dart';
import '../models/flashcard_model.dart';
import '../models/habit_model.dart';
import '../models/note_model.dart';
import '../models/planner_model.dart';
import '../models/quiz_model.dart';
import '../models/sync_status.dart';
import '../models/task_model.dart';
import '../models/timetable_model.dart';
import 'firebase_service.dart';

class SyncResult {
  final bool isSuccess;
  final int uploadedCount;
  final int downloadedCount;
  final String? errorMessage;
  final DateTime timestamp;

  const SyncResult({
    required this.isSuccess,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    this.errorMessage,
    required this.timestamp,
  });

  int get totalItems => uploadedCount + downloadedCount;
}

class SyncState {
  final bool isSyncing;
  final DateTime? lastSyncedAt;
  final String? lastError;
  final int totalSynced;
  final bool isCloudConnected;

  const SyncState({
    this.isSyncing = false,
    this.lastSyncedAt,
    this.lastError,
    this.totalSynced = 0,
    this.isCloudConnected = false,
  });

  SyncState copyWith({
    bool? isSyncing,
    DateTime? lastSyncedAt,
    String? lastError,
    int? totalSynced,
    bool? isCloudConnected,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: lastError,
      totalSynced: totalSynced ?? this.totalSynced,
      isCloudConnected: isCloudConnected ?? this.isCloudConnected,
    );
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final firebase = ref.watch(firebaseServiceProvider);
  return SyncService(db, firebase);
});

final syncStateProvider =
    StateNotifierProvider<SyncStateNotifier, SyncState>((ref) {
      final syncService = ref.watch(syncServiceProvider);
      return SyncStateNotifier(syncService);
    });

class SyncStateNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;

  SyncStateNotifier(this._syncService)
    : super(SyncState(isCloudConnected: _syncService.isCloudAvailable));

  Future<SyncResult> triggerSync(String userId) async {
    if (state.isSyncing) {
      return SyncResult(
        isSuccess: false,
        errorMessage: 'A sync is already in progress.',
        timestamp: DateTime.now(),
      );
    }

    state = state.copyWith(
      isSyncing: true,
      lastError: null,
      isCloudConnected: _syncService.isCloudAvailable,
    );

    try {
      final result = await _syncService.syncAll(userId);
      state = state.copyWith(
        isSyncing: false,
        lastSyncedAt: result.timestamp,
        totalSynced: result.totalItems,
        lastError: result.errorMessage,
        isCloudConnected: _syncService.isCloudAvailable,
      );
      return result;
    } catch (e) {
      final errorMsg = e.toString();
      state = state.copyWith(
        isSyncing: false,
        lastError: errorMsg,
        isCloudConnected: _syncService.isCloudAvailable,
      );
      return SyncResult(
        isSuccess: false,
        errorMessage: errorMsg,
        timestamp: DateTime.now(),
      );
    }
  }
}

class SyncService {
  final AppDatabase _db;
  final FirebaseService _firebaseService;

  SyncService(this._db, this._firebaseService);

  bool get isCloudAvailable => _firebaseService.isConfigured;

  /// Performs full bidirectional synchronization between local SQLite and Cloud Firestore
  Future<SyncResult> syncAll(String userId) async {
    final timestamp = DateTime.now();

    if (!isCloudAvailable || userId.isEmpty || userId == 'guest') {
      debugPrint('Sync skipped: Cloud not configured or guest user');
      return SyncResult(
        isSuccess: true,
        uploadedCount: 0,
        downloadedCount: 0,
        timestamp: timestamp,
      );
    }

    int uploaded = 0;
    int downloaded = 0;

    try {
      // 1. Notes Sync
      final notesResult = await _syncNotes(userId);
      uploaded += notesResult.$1;
      downloaded += notesResult.$2;

      // 2. Tasks Sync
      final tasksResult = await _syncTasks(userId);
      uploaded += tasksResult.$1;
      downloaded += tasksResult.$2;

      // 3. Timetable Sync
      final timetableResult = await _syncTimetable(userId);
      uploaded += timetableResult.$1;
      downloaded += timetableResult.$2;

      // 4. Exams Sync
      final examsResult = await _syncExams(userId);
      uploaded += examsResult.$1;
      downloaded += examsResult.$2;

      // 5. Habits Sync
      final habitsResult = await _syncHabits(userId);
      uploaded += habitsResult.$1;
      downloaded += habitsResult.$2;

      // 6. Flashcard Decks & Cards Sync
      final flashcardsResult = await _syncFlashcards(userId);
      uploaded += flashcardsResult.$1;
      downloaded += flashcardsResult.$2;

      // 7. Planner Study Sessions Sync
      final plannerResult = await _syncPlannerSessions(userId);
      uploaded += plannerResult.$1;
      downloaded += plannerResult.$2;

      // 8. Quiz Attempts & Summary Sync
      final quizResult = await _syncQuizAttempts(userId);
      uploaded += quizResult.$1;
      downloaded += quizResult.$2;

      // 9. Update user stats snapshot in Firestore
      await _updateCloudStats(userId, timestamp);

      debugPrint(
        'Full cloud sync finished: $uploaded uploaded, $downloaded downloaded',
      );

      return SyncResult(
        isSuccess: true,
        uploadedCount: uploaded,
        downloadedCount: downloaded,
        timestamp: timestamp,
      );
    } catch (e) {
      debugPrint('Cloud sync error: $e');
      return SyncResult(
        isSuccess: false,
        uploadedCount: uploaded,
        downloadedCount: downloaded,
        errorMessage: e.toString(),
        timestamp: timestamp,
      );
    }
  }

  // --- 1. Notes Sync ---
  Future<(int, int)> _syncNotes(String userId) async {
    int up = 0, down = 0;
    final col = _firebaseService.getUserCollection(userId, 'notes');
    if (col == null) return (0, 0);

    // Push local to remote
    final localList = await _db.getNotes(userId);
    for (final item in localList) {
      await col.doc(item.id).set(item.toFirestoreMap(), SetOptions(merge: true));
      if (item.syncStatus != SyncStatus.synced) {
        await _db.updateNote(item.copyWith(syncStatus: SyncStatus.synced));
        up++;
      }
    }

    // Pull remote to local
    final snap = await col.get();
    for (final doc in snap.docs) {
      final remoteItem = NoteModel.fromMap(doc.data());
      await _db.insertNote(remoteItem.copyWith(syncStatus: SyncStatus.synced));
      down++;
    }

    return (up, down);
  }

  // --- 2. Tasks Sync ---
  Future<(int, int)> _syncTasks(String userId) async {
    int up = 0, down = 0;
    final col = _firebaseService.getUserCollection(userId, 'tasks');
    if (col == null) return (0, 0);

    final localList = await _db.getTasks(userId);
    for (final item in localList) {
      await col.doc(item.id).set(item.toFirestoreMap(), SetOptions(merge: true));
      if (item.syncStatus != SyncStatus.synced) {
        await _db.updateTask(item.copyWith(syncStatus: SyncStatus.synced));
        up++;
      }
    }

    final snap = await col.get();
    for (final doc in snap.docs) {
      final remoteItem = TaskModel.fromMap(doc.data());
      await _db.insertTask(remoteItem.copyWith(syncStatus: SyncStatus.synced));
      down++;
    }

    return (up, down);
  }

  // --- 3. Timetable Sync ---
  Future<(int, int)> _syncTimetable(String userId) async {
    int up = 0, down = 0;
    final col = _firebaseService.getUserCollection(userId, 'timetable');
    if (col == null) return (0, 0);

    final localList = await _db.getTimetable(userId);
    for (final item in localList) {
      await col.doc(item.id).set(item.toFirestoreMap(), SetOptions(merge: true));
      if (item.syncStatus != SyncStatus.synced) {
        await _db.updateTimetable(item.copyWith(syncStatus: SyncStatus.synced));
        up++;
      }
    }

    final snap = await col.get();
    for (final doc in snap.docs) {
      final remoteItem = TimetableModel.fromMap(doc.data());
      await _db.insertTimetable(remoteItem.copyWith(syncStatus: SyncStatus.synced));
      down++;
    }

    return (up, down);
  }

  // --- 4. Exams Sync ---
  Future<(int, int)> _syncExams(String userId) async {
    int up = 0, down = 0;
    final col = _firebaseService.getUserCollection(userId, 'exams');
    if (col == null) return (0, 0);

    final localList = await _db.getExams(userId);
    for (final item in localList) {
      await col.doc(item.id).set(item.toFirestoreMap(), SetOptions(merge: true));
      if (item.syncStatus != SyncStatus.synced) {
        await _db.updateExam(item.copyWith(syncStatus: SyncStatus.synced));
        up++;
      }
    }

    final snap = await col.get();
    for (final doc in snap.docs) {
      final remoteItem = ExamModel.fromMap(doc.data());
      await _db.insertExam(remoteItem.copyWith(syncStatus: SyncStatus.synced));
      down++;
    }

    return (up, down);
  }

  // --- 5. Habits Sync ---
  Future<(int, int)> _syncHabits(String userId) async {
    int up = 0, down = 0;
    final col = _firebaseService.getUserCollection(userId, 'habits');
    if (col == null) return (0, 0);

    final localList = await _db.getHabits(userId);
    for (final item in localList) {
      await col.doc(item.id).set(item.toMap(), SetOptions(merge: true));
      if (item.syncStatus != SyncStatus.synced) {
        await _db.updateHabit(
          HabitModel(
            id: item.id,
            userId: item.userId,
            title: item.title,
            description: item.description,
            iconName: item.iconName,
            colorHex: item.colorHex,
            targetDaysPerWeek: item.targetDaysPerWeek,
            currentStreak: item.currentStreak,
            bestStreak: item.bestStreak,
            completedDates: item.completedDates,
            reminderTime: item.reminderTime,
            createdAt: item.createdAt,
            syncStatus: SyncStatus.synced,
          ),
        );
        up++;
      }
    }

    final snap = await col.get();
    for (final doc in snap.docs) {
      final remoteItem = HabitModel.fromMap(doc.data());
      await _db.insertHabit(
        HabitModel(
          id: remoteItem.id,
          userId: remoteItem.userId,
          title: remoteItem.title,
          description: remoteItem.description,
          iconName: remoteItem.iconName,
          colorHex: remoteItem.colorHex,
          targetDaysPerWeek: remoteItem.targetDaysPerWeek,
          currentStreak: remoteItem.currentStreak,
          bestStreak: remoteItem.bestStreak,
          completedDates: remoteItem.completedDates,
          reminderTime: remoteItem.reminderTime,
          createdAt: remoteItem.createdAt,
          syncStatus: SyncStatus.synced,
        ),
      );
      down++;
    }

    return (up, down);
  }

  // --- 6. Flashcards Sync ---
  Future<(int, int)> _syncFlashcards(String userId) async {
    int up = 0, down = 0;
    final decksCol = _firebaseService.getUserCollection(
      userId,
      'flashcard_decks',
    );
    final cardsCol = _firebaseService.getUserCollection(userId, 'flashcards');
    if (decksCol == null || cardsCol == null) return (0, 0);

    // Sync Decks
    final localDecks = await _db.getFlashcardDecks(userId);
    for (final deck in localDecks) {
      await decksCol.doc(deck.id).set(deck.toMap(), SetOptions(merge: true));
      up++;

      // Sync cards for each deck
      final cards = await _db.getFlashcards(deck.id);
      for (final card in cards) {
        await cardsCol.doc(card.id).set(card.toMap(), SetOptions(merge: true));
        up++;
      }
    }

    // Pull Decks & Cards from Cloud
    final decksSnap = await decksCol.get();
    for (final doc in decksSnap.docs) {
      final remoteDeck = FlashcardDeckModel.fromMap(doc.data());
      await _db.insertFlashcardDeck(remoteDeck);
      down++;
    }

    final cardsSnap = await cardsCol.get();
    for (final doc in cardsSnap.docs) {
      final remoteCard = FlashcardModel.fromMap(doc.data());
      await _db.insertFlashcard(remoteCard);
      down++;
    }

    return (up, down);
  }

  // --- 7. Planner Sessions Sync ---
  Future<(int, int)> _syncPlannerSessions(String userId) async {
    int up = 0, down = 0;
    final col = _firebaseService.getUserCollection(userId, 'study_sessions');
    if (col == null) return (0, 0);

    final localSessions = await _db.getStudySessions(userId);
    for (final s in localSessions) {
      await col.doc(s.id).set(s.toMap(), SetOptions(merge: true));
      up++;
    }

    final snap = await col.get();
    for (final doc in snap.docs) {
      final remoteSession = StudySessionModel.fromMap(doc.data());
      await _db.insertStudySession(remoteSession);
      down++;
    }

    return (up, down);
  }

  // --- 8. Quiz Attempts Sync ---
  Future<(int, int)> _syncQuizAttempts(String userId) async {
    int up = 0, down = 0;
    final col = _firebaseService.getUserCollection(userId, 'quiz_attempts');
    if (col == null) return (0, 0);

    final localAttempts = await _db.getQuizAttempts(userId);
    for (final a in localAttempts) {
      await col.doc(a.id).set(a.toMap(), SetOptions(merge: true));
      up++;
    }

    final snap = await col.get();
    for (final doc in snap.docs) {
      final remoteAttempt = QuizAttempt.fromMap(doc.data());
      await _db.insertQuizAttempt(remoteAttempt);
      down++;
    }

    return (up, down);
  }

  // --- 9. Cloud Stats Summary ---
  Future<void> _updateCloudStats(String userId, DateTime timestamp) async {
    if (_firebaseService.firestore == null) return;
    try {
      final notes = await _db.getNotes(userId);
      final tasks = await _db.getTasks(userId);
      final habits = await _db.getHabits(userId);
      final exams = await _db.getExams(userId);
      final decks = await _db.getFlashcardDecks(userId);

      final completedTasks = tasks.where((t) => t.isCompleted).length;
      final bestStreak = habits.fold<int>(
        0,
        (max, h) => h.bestStreak > max ? h.bestStreak : max,
      );

      final doc = _firebaseService.firestore!
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('summary');

      await doc.set({
        'totalNotes': notes.length,
        'totalTasks': tasks.length,
        'completedTasks': completedTasks,
        'activeHabits': habits.length,
        'bestStreak': bestStreak,
        'upcomingExams': exams.where((e) => !e.isCompleted).length,
        'flashcardDecks': decks.length,
        'lastSyncedAt': timestamp.toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Warning updating cloud stats: $e');
    }
  }
}
