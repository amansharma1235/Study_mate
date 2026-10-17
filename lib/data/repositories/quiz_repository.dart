import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_database.dart';
import '../models/quiz_model.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return QuizRepository(db);
});

class QuizRepository {
  final AppDatabase _db;
  List<QuizQuestion>? _cachedQuestions;

  QuizRepository(this._db);

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
  }

  Future<List<QuizAttempt>> getAttempts(String userId) async {
    return await _db.getQuizAttempts(userId);
  }
}
