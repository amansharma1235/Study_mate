import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_database.dart';
import '../models/quiz_model.dart';

import '../remote/firebase_service.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  return QuizRepository(db, firebaseService: firebaseService);
});

class QuizRepository {
  final AppDatabase _db;
  final FirebaseService? firebaseService;
  List<QuizQuestion>? _cachedQuestions;

  QuizRepository(this._db, {this.firebaseService});

  Future<List<QuizQuestion>> getAllQuestions() async {
    if (_cachedQuestions != null) return _cachedQuestions!;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/quiz_questions.json',
      );
      final list = jsonDecode(jsonString) as List;
      _cachedQuestions = list
          .map((item) => QuizQuestion.fromMap(item as Map<String, dynamic>))
          .toList();
      return _cachedQuestions!;
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> getCategories() async {
    final questions = await getAllQuestions();
    return questions.map((q) => q.category).toSet().toList();
  }

  Future<List<QuizQuestion>> getQuestionsByCategory(String category) async {
    final questions = await getAllQuestions();
    if (category.isEmpty || category == 'All') return questions;
    return questions.where((q) => q.category == category).toList();
  }

  Future<void> saveAttempt(QuizAttempt attempt) async {
    await _db.insertQuizAttempt(attempt);

    final fb = firebaseService;
    if (fb != null && fb.isConfigured && attempt.userId.isNotEmpty) {
      try {
        final col = fb.getUserCollection(
          attempt.userId,
          'quiz_attempts',
        );
        if (col != null) {
          await col.doc(attempt.id).set(attempt.toMap());
        }
      } catch (e) {
        // Soft fallback
      }
    }
  }

  Future<List<QuizAttempt>> getAttempts(String userId) async {
    final localAttempts = await _db.getQuizAttempts(userId);

    final fb = firebaseService;
    if (fb != null && fb.isConfigured && userId.isNotEmpty) {
      _syncFromRemote(userId).catchError((_) => <QuizAttempt>[]);
    }

    return localAttempts;
  }

  Future<List<QuizAttempt>> _syncFromRemote(String userId) async {
    final col = firebaseService?.getUserCollection(userId, 'quiz_attempts');
    if (col == null) return [];

    final snap = await col.get();
    final remoteAttempts = snap.docs
        .map((doc) => QuizAttempt.fromMap(doc.data()))
        .toList();

    for (final attempt in remoteAttempts) {
      await _db.insertQuizAttempt(attempt);
    }
    return remoteAttempts;
  }
}
