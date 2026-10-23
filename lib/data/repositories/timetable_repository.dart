import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sync_status.dart';
import '../models/timetable_model.dart';
import '../remote/firebase_service.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return TimetableRepository(firebaseService);
});

/// Pure Cloud-First Timetable Repository.
/// All timetable schedules are saved to Cloud Firestore (users/{userId}/timetable).
/// In-memory state is maintained temporarily during execution.
/// No schedule records are persisted locally in SQLite or local files.
class TimetableRepository {
  final FirebaseService _firebaseService;
  final Map<String, List<TimetableModel>> _sessionCache = {};

  TimetableRepository(this._firebaseService);

  Future<List<TimetableModel>> getTimetable(String userId) async {
    if (userId.isEmpty) return [];

    if (_firebaseService.isConfigured && userId != 'guest') {
      try {
        final col = _firebaseService.getUserCollection(userId, 'timetable');
        if (col != null) {
          final snapshot = await col
              .orderBy('dayOfWeek', descending: false)
              .orderBy('startTime', descending: false)
              .get();
          final entries = snapshot.docs
              .map((doc) => TimetableModel.fromMap(doc.data()))
              .toList();
          _sessionCache[userId] = entries;
          return entries;
        }
      } catch (e) {
        debugPrint('Cloud timetable fetch notice: $e');
        return _sessionCache[userId] ?? [];
      }
    }

    return _sessionCache[userId] ?? [];
  }

  Future<void> saveTimetable(TimetableModel entry) async {
    final entryWithSync = entry.copyWith(syncStatus: SyncStatus.synced);

    final list = _sessionCache[entry.userId] ?? [];
    final index = list.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      list[index] = entryWithSync;
    } else {
      list.add(entryWithSync);
    }
    _sessionCache[entry.userId] = list;

    if (_firebaseService.isConfigured && entry.userId.isNotEmpty && entry.userId != 'guest') {
      final col = _firebaseService.getUserCollection(entry.userId, 'timetable');
      if (col != null) {
        await col.doc(entry.id).set(entryWithSync.toFirestoreMap());
      }
    }
  }

  Future<void> deleteTimetable(String id, String userId) async {
    if (_sessionCache.containsKey(userId)) {
      _sessionCache[userId]!.removeWhere((e) => e.id == id);
    }

    if (_firebaseService.isConfigured && userId.isNotEmpty && userId != 'guest') {
      final col = _firebaseService.getUserCollection(userId, 'timetable');
      if (col != null) {
        await col.doc(id).delete();
      }
    }
  }
}
