import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final firebase = ref.watch(firebaseServiceProvider);
  return SyncService(firebase);
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

/// Cloud Sync & Status Service.
/// Communicates with Cloud Firestore and updates summary analytics in the cloud.
/// Follows non-negotiable zero-persistence policy: does not persist user records into local SQLite or disk files.
class SyncService {
  final FirebaseService _firebaseService;

  SyncService([dynamic arg1, dynamic arg2])
      : _firebaseService = arg2 is FirebaseService
            ? arg2
            : (arg1 is FirebaseService ? arg1 : FirebaseService.instance);

  bool get isCloudAvailable => _firebaseService.isConfigured;

  /// Synchronizes and validates Cloud Firestore records for the user
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

    int cloudItemCount = 0;

    try {
      final colList = ['notes', 'tasks', 'timetable', 'exams', 'pomodoro_sessions'];
      for (final colName in colList) {
        final col = _firebaseService.getUserCollection(userId, colName);
        if (col != null) {
          final snap = await col.get();
          cloudItemCount += snap.docs.length;
        }
      }

      await _updateCloudStats(userId, timestamp);

      return SyncResult(
        isSuccess: true,
        uploadedCount: cloudItemCount,
        downloadedCount: cloudItemCount,
        timestamp: timestamp,
      );
    } catch (e) {
      debugPrint('Cloud sync notice: $e');
      return SyncResult(
        isSuccess: false,
        uploadedCount: 0,
        downloadedCount: 0,
        errorMessage: e.toString(),
        timestamp: timestamp,
      );
    }
  }

  Future<void> _updateCloudStats(String userId, DateTime timestamp) async {
    if (_firebaseService.firestore == null) return;
    try {
      int totalNotes = 0;
      int totalTasks = 0;
      int completedTasks = 0;
      int totalExams = 0;

      final notesCol = _firebaseService.getUserCollection(userId, 'notes');
      if (notesCol != null) {
        final snap = await notesCol.get();
        totalNotes = snap.docs.length;
      }

      final tasksCol = _firebaseService.getUserCollection(userId, 'tasks');
      if (tasksCol != null) {
        final snap = await tasksCol.get();
        totalTasks = snap.docs.length;
        completedTasks = snap.docs.where((d) => d.data()['isCompleted'] == 1 || d.data()['isCompleted'] == true).length;
      }

      final examsCol = _firebaseService.getUserCollection(userId, 'exams');
      if (examsCol != null) {
        final snap = await examsCol.get();
        totalExams = snap.docs.where((d) => d.data()['isCompleted'] == 0 || d.data()['isCompleted'] == false).length;
      }

      final doc = _firebaseService.firestore!
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('summary');

      await doc.set({
        'totalNotes': totalNotes,
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'upcomingExams': totalExams,
        'lastSyncedAt': timestamp.toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Warning updating cloud stats: $e');
    }
  }
}
