import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/quiz_model.dart';
import '../../data/repositories/quiz_repository.dart';
import '../auth/auth_controller.dart';

class QuizSessionState {
  final String category;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final Map<int, int> selectedAnswers; // questionIndex -> optionIndex
  final bool isSubmitted;
  final int correctCount;
  final double scorePercentage;

  const QuizSessionState({
    required this.category,
    required this.questions,
    this.currentIndex = 0,
    this.selectedAnswers = const {},
    this.isSubmitted = false,
    this.correctCount = 0,
    this.scorePercentage = 0.0,
  });

  QuizQuestion? get currentQuestion =>
      questions.isNotEmpty && currentIndex < questions.length
      ? questions[currentIndex]
      : null;

  bool get isLastQuestion => currentIndex == questions.length - 1;

  QuizSessionState copyWith({
    String? category,
    List<QuizQuestion>? questions,
    int? currentIndex,
    Map<int, int>? selectedAnswers,
    bool? isSubmitted,
    int? correctCount,
    double? scorePercentage,
  }) {
    return QuizSessionState(
      category: category ?? this.category,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      correctCount: correctCount ?? this.correctCount,
      scorePercentage: scorePercentage ?? this.scorePercentage,
    );
  }
}

final quizSessionControllerProvider =
    StateNotifierProvider<QuizSessionController, QuizSessionState>((ref) {
      final repo = ref.watch(quizRepositoryProvider);
      final user = ref.watch(currentProfileProvider);
      final userId = user?.uid ?? 'guest';
      return QuizSessionController(repo, userId);
    });

class QuizSessionController extends StateNotifier<QuizSessionState> {
  final QuizRepository _repo;
  final String _userId;

  QuizSessionController(this._repo, this._userId)
    : super(const QuizSessionState(category: '', questions: []));

  Future<void> startQuiz(String category) async {
    final questions = await _repo.getQuestionsByCategory(category);
    questions.shuffle();

    state = QuizSessionState(
      category: category,
      questions: questions,
      currentIndex: 0,
      selectedAnswers: {},
      isSubmitted: false,
      correctCount: 0,
      scorePercentage: 0.0,
    );
  }

  void selectOption(int optionIndex) {
    if (state.isSubmitted) return;

    final updated = Map<int, int>.from(state.selectedAnswers);
    updated[state.currentIndex] = optionIndex;
    state = state.copyWith(selectedAnswers: updated);
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  Future<void> submitQuiz() async {
    int correct = 0;
    for (int i = 0; i < state.questions.length; i++) {
      final selected = state.selectedAnswers[i];
      if (selected != null && selected == state.questions[i].correctIndex) {
        correct++;
      }
    }

    final percentage = state.questions.isEmpty
        ? 0.0
        : (correct / state.questions.length) * 100.0;

    state = state.copyWith(
      isSubmitted: true,
      correctCount: correct,
      scorePercentage: percentage,
    );

    // Save attempt to repository
    final attempt = QuizAttempt(
      id: const Uuid().v4(),
      userId: _userId,
      category: state.category,
      totalQuestions: state.questions.length,
      correctAnswers: correct,
      scorePercentage: percentage,
      completedAt: DateTime.now(),
    );

    await _repo.saveAttempt(attempt);
  }
}

final quizCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(quizRepositoryProvider);
  return await repo.getCategories();
});

final quizAttemptsHistoryProvider = FutureProvider<List<QuizAttempt>>((
  ref,
) async {
  final repo = ref.watch(quizRepositoryProvider);
  final user = ref.watch(currentProfileProvider);
  final userId = user?.uid ?? 'guest';
  return await repo.getAttempts(userId);
});
