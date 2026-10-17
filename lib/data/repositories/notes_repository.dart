import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_database.dart';
import '../models/note_model.dart';
import '../models/sync_status.dart';
import '../remote/firebase_service.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  return NotesRepository(db, firebaseService);
});

class NotesRepository {
  final AppDatabase _db;
  final FirebaseService _firebaseService;

  NotesRepository(this._db, this._firebaseService);

  Future<List<NoteModel>> getNotes(String userId) async {
    final localNotes = await _db.getNotes(userId);

    // Sync in background if Firebase is configured
    if (_firebaseService.isConfigured && userId.isNotEmpty) {
      _syncFromRemote(userId).catchError((e) {
        debugPrint('Notes sync warning: $e');
        return <NoteModel>[];
      });
    }

    return localNotes;
  }

  Future<void> saveNote(NoteModel note) async {
    // Save to local SQLite first
    await _db.insertNote(note);

    // If Firebase configured, sync to Firestore
    if (_firebaseService.isConfigured && note.userId.isNotEmpty) {
      try {
        final col = _firebaseService.getUserCollection(note.userId, 'notes');
        if (col != null) {
          await col.doc(note.id).set(note.toFirestoreMap());
          await _db.updateNote(note.copyWith(syncStatus: SyncStatus.synced));
        }
      } catch (e) {
        debugPrint('Firestore note upload failed, marked pending: $e');
        await _db.updateNote(note.copyWith(syncStatus: SyncStatus.pendingSync));
      }
    }
  }

  Future<void> deleteNote(String id, String userId) async {
    await _db.deleteNote(id);

    if (_firebaseService.isConfigured && userId.isNotEmpty) {
      try {
        final col = _firebaseService.getUserCollection(userId, 'notes');
        if (col != null) {
          await col.doc(id).delete();
        }
      } catch (e) {
        debugPrint('Firestore note delete warning: $e');
      }
    }
  }

  Future<List<NoteModel>> _syncFromRemote(String userId) async {
    final col = _firebaseService.getUserCollection(userId, 'notes');
    if (col == null) return [];

    final snapshot = await col.get();
    final remoteNotes = snapshot.docs
        .map((doc) => NoteModel.fromMap(doc.data()))
        .toList();

    for (final note in remoteNotes) {
      await _db.insertNote(note.copyWith(syncStatus: SyncStatus.synced));
    }
    return remoteNotes;
  }
}
