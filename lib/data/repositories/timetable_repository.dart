import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_database.dart';
import '../models/sync_status.dart';
import '../models/timetable_model.dart';
import '../remote/firebase_service.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  return TimetableRepository(db, firebaseService);
});

class TimetableRepository {
  final AppDatabase _db;
  final FirebaseService _firebaseService;

  TimetableRepository(this._db, this._firebaseService);

  Future<List<TimetableModel>> getTimetable(String userId) async {
    final localEntries = await _db.getTimetable(userId);

    if (_firebaseService.isConfigured && userId.isNotEmpty) {
      _syncFromRemote(userId).catchError((e) {
        debugPrint('Timetable remote sync notice: $e');
        return <TimetableModel>[];
      });
    }

    return localEntries;
  }

  Future<void> saveTimetable(TimetableModel entry) async {
    await _db.insertTimetable(entry);

    if (_firebaseService.isConfigured && entry.userId.isNotEmpty) {
      try {
        final col = _firebaseService.getUserCollection(
          entry.userId,
          'timetable',
        );
        if (col != null) {
          await col.doc(entry.id).set(entry.toFirestoreMap());
          await _db.updateTimetable(
            entry.copyWith(syncStatus: SyncStatus.synced),
          );
        }
      } catch (e) {
        debugPrint('Firestore timetable upload warning: $e');
        await _db.updateTimetable(
          entry.copyWith(syncStatus: SyncStatus.pendingSync),
        );
      }
    }
  }

  Future<void> deleteTimetable(String id, String userId) async {
    await _db.deleteTimetable(id);

    if (_firebaseService.isConfigured && userId.isNotEmpty) {
      try {
        final col = _firebaseService.getUserCollection(userId, 'timetable');
        if (col != null) {
          await col.doc(id).delete();
        }
      } catch (e) {
        debugPrint('Firestore timetable delete warning: $e');
      }
    }
  }

  Future<List<TimetableModel>> _syncFromRemote(String userId) async {
    final col = _firebaseService.getUserCollection(userId, 'timetable');
    if (col == null) return [];

    final snapshot = await col.get();
    final remoteEntries = snapshot.docs
        .map((doc) => TimetableModel.fromMap(doc.data()))
        .toList();

    for (final entry in remoteEntries) {
      await _db.insertTimetable(entry.copyWith(syncStatus: SyncStatus.synced));
    }
    return remoteEntries;
  }
}
