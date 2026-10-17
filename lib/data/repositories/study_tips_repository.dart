import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_database.dart';
import '../models/study_tip_model.dart';

final studyTipsRepositoryProvider = Provider<StudyTipsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return StudyTipsRepository(db);
});

class StudyTipsRepository {
  final AppDatabase _db;
  List<StudyTipModel>? _cachedTips;

  StudyTipsRepository(this._db);

  Future<List<StudyTipModel>> getAllTips() async {
    final saved = await _db.getSavedTips();
    final savedIds = saved.map((s) => s.id).toSet();

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

  Future<List<StudyTipModel>> getSavedTips() async {
    return await _db.getSavedTips();
  }

  Future<void> toggleFavorite(StudyTipModel tip) async {
    final saved = await _db.getSavedTips();
    final isAlreadySaved = saved.any((s) => s.id == tip.id);

    if (isAlreadySaved) {
      await _db.deleteSavedTip(tip.id);
    } else {
      await _db.insertSavedTip(tip.copyWith(isFavorite: true));
    }
  }
}
