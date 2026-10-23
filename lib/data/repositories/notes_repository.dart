import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_model.dart';
import '../models/sync_status.dart';
import '../remote/firebase_service.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return NotesRepository(firebaseService);
});

/// Pure Cloud-First Notes Repository.
/// All user-generated content is saved to and retrieved from Cloud Firestore (users/{userId}/notes).
/// In-memory session state is retained only during app execution for UI responsiveness.
/// No user notes are persisted to SQLite or local device files.
class NotesRepository {
  final FirebaseService _firebaseService;
  final Map<String, List<NoteModel>> _sessionCache = {};

  NotesRepository(this._firebaseService);

  Future<List<NoteModel>> getNotes(String userId) async {
    if (userId.isEmpty) return [];

    if (_firebaseService.isConfigured && userId != 'guest') {
      try {
        final col = _firebaseService.getUserCollection(userId, 'notes');
        if (col != null) {
          final snapshot = await col.orderBy('updatedAt', descending: true).get();
          final notes = snapshot.docs
              .map((doc) => NoteModel.fromMap(doc.data()))
              .toList();
          _sessionCache[userId] = notes;
          return notes;
        }
      } catch (e) {
        debugPrint('Cloud notes fetch notice: $e');
        return _sessionCache[userId] ?? [];
      }
    }

    return _sessionCache[userId] ?? [];
  }

  Future<void> saveNote(NoteModel note) async {
    final noteWithSync = note.copyWith(syncStatus: SyncStatus.synced);

    final list = _sessionCache[note.userId] ?? [];
    final index = list.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      list[index] = noteWithSync;
    } else {
      list.insert(0, noteWithSync);
    }
    _sessionCache[note.userId] = list;

    if (_firebaseService.isConfigured && note.userId.isNotEmpty && note.userId != 'guest') {
      final col = _firebaseService.getUserCollection(note.userId, 'notes');
      if (col != null) {
        await col.doc(note.id).set(noteWithSync.toFirestoreMap());
      }
    }
  }

  Future<void> deleteNote(String id, String userId) async {
    if (_sessionCache.containsKey(userId)) {
      _sessionCache[userId]!.removeWhere((n) => n.id == id);
    }

    if (_firebaseService.isConfigured && userId.isNotEmpty && userId != 'guest') {
      final col = _firebaseService.getUserCollection(userId, 'notes');
      if (col != null) {
        await col.doc(id).delete();
      }
    }
  }
}
