import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/study_tip_model.dart';
import '../remote/firebase_service.dart';

final studyTipsRepositoryProvider = Provider<StudyTipsRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return StudyTipsRepository(firebaseService);
});

/// Pure Cloud-First Study Tips Repository.
/// Bundled educational content is a read-only asset (Section 6.I).
/// Saved bookmarks and favorites are backed by Cloud Firestore (users/{userId}/saved_tips).
/// In-memory state is maintained temporarily during execution.
/// No bookmarks are persisted locally in SQLite or local files.
class StudyTipsRepository {
  final FirebaseService _firebaseService;
  List<StudyTipModel>? _cachedTips;
  final Map<String, Set<String>> _sessionFavorites = {};

  StudyTipsRepository(this._firebaseService);

  Future<List<StudyTipModel>> getAllTips({String userId = ''}) async {
    Set<String> savedIds = {};
    if (userId.isNotEmpty) {
      savedIds = await getSavedTipIds(userId);
    }

    if (_cachedTips == null) {
      try {
        final jsonString = await rootBundle.loadString(
          'assets/data/study_tips.json',
        );
        final list = jsonDecode(jsonString) as List;
        _cachedTips = list
            .map((item) => StudyTipModel.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _cachedTips = [];
      }
    }

    return _cachedTips!.map((tip) {
      return tip.copyWith(isFavorite: savedIds.contains(tip.id));
    }).toList();
  }

  Future<Set<String>> getSavedTipIds(String userId) async {
    if (userId.isEmpty) return {};

    if (_firebaseService.isConfigured && userId != 'guest') {
      try {
        final col = _firebaseService.getUserCollection(userId, 'saved_tips');
        if (col != null) {
          final snap = await col.get();
          final ids = snap.docs.map((d) => d.id).toSet();
          _sessionFavorites[userId] = ids;
          return ids;
        }
      } catch (e) {
        debugPrint('Cloud saved tips fetch notice: $e');
      }
    }

    return _sessionFavorites[userId] ?? {};
  }

  Future<List<StudyTipModel>> getSavedTips({String userId = ''}) async {
    final all = await getAllTips(userId: userId);
    return all.where((t) => t.isFavorite).toList();
  }

  Future<void> toggleFavorite(StudyTipModel tip, {String userId = ''}) async {
    final currentSet = _sessionFavorites[userId] ?? {};
    final isAlreadySaved = currentSet.contains(tip.id);

    if (isAlreadySaved) {
      currentSet.remove(tip.id);
    } else {
      currentSet.add(tip.id);
    }
    _sessionFavorites[userId] = currentSet;

    if (_firebaseService.isConfigured &&
        userId.isNotEmpty &&
        userId != 'guest') {
      final col = _firebaseService.getUserCollection(userId, 'saved_tips');
      if (col != null) {
        if (isAlreadySaved) {
          await col.doc(tip.id).delete();
        } else {
          await col.doc(tip.id).set({
            'id': tip.id,
            'title': tip.title,
            'category': tip.category,
            'summary': tip.summary,
            'savedAt': DateTime.now().toIso8601String(),
          });
        }
      }
    }
  }
}
