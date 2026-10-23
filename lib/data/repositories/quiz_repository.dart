import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quiz_model.dart';
import '../remote/firebase_service.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return QuizRepository(firebaseService: firebaseService);
});

/// Pure Cloud-First Quiz Repository.
/// Question bank is bundled as read-only application asset (Section 6.G).
/// Quiz attempt history is stored in Cloud Firestore (users/{userId}/quiz_attempts).
/// In-memory state is maintained temporarily during execution.
/// No quiz attempts are persisted locally in SQLite or local files.
class QuizRepository {
  final FirebaseService? firebaseService;
  List<QuizQuestion>? _cachedQuestions;
  final Map<String, List<QuizAttempt>> _sessionAttempts = {};

  QuizRepository({this.firebaseService});

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
    final list = _sessionAttempts[attempt.userId] ?? [];
    list.insert(0, attempt);
    _sessionAttempts[attempt.userId] = list;

    final fb = firebaseService;
    if (fb != null &&
        fb.isConfigured &&
        attempt.userId.isNotEmpty &&
        attempt.userId != 'guest') {
      try {
        final col = fb.getUserCollection(attempt.userId, 'quiz_attempts');
        if (col != null) {
          await col.doc(attempt.id).set(attempt.toMap());
        }
      } catch (e) {
        debugPrint('Cloud quiz attempt record notice: $e');
      }
    }
  }

  Future<List<QuizAttempt>> getAttempts(String userId) async {
    if (userId.isEmpty) return [];

    final fb = firebaseService;
    if (fb != null && fb.isConfigured && userId != 'guest') {
      try {
        final col = fb.getUserCollection(userId, 'quiz_attempts');
        if (col != null) {
          final snap = await col.orderBy('completedAt', descending: true).get();
          final attempts = snap.docs
              .map((doc) => QuizAttempt.fromMap(doc.data()))
              .toList();
          _sessionAttempts[userId] = attempts;
          return attempts;
        }
      } catch (e) {
        debugPrint('Cloud quiz attempts fetch notice: $e');
        if (_sessionAttempts.containsKey(userId)) {
          return _sessionAttempts[userId]!;
        }
      }
    }

    return _sessionAttempts[userId] ?? [];
  }
}
