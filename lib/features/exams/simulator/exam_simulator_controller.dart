import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/exam_simulator_service.dart';
import '../../../data/models/exam_simulator_model.dart';
import '../../gamification/gamification_controller.dart';

class ExamSimulatorState {
  final ExamSimConfig? config;
  final List<ExamSimQuestion> questions;
  final int currentIndex;
  final int remainingSeconds;
  final int totalDurationSeconds;
  final bool isRunning;
  final bool isSubmitting;
  final ExamSimResult? result;

  const ExamSimulatorState({
    this.config,
    this.questions = const [],
    this.currentIndex = 0,
    this.remainingSeconds = 0,
    this.totalDurationSeconds = 0,
    this.isRunning = false,
    this.isSubmitting = false,
    this.result,
  });

  ExamSimQuestion? get currentQuestion =>
      questions.isNotEmpty && currentIndex < questions.length
          ? questions[currentIndex]
          : null;

  int get attemptedCount => questions.where((q) => q.isAttempted).length;
  int get markedReviewCount => questions.where((q) => q.isMarkedForReview).length;
  int get unattemptedCount => questions.length - attemptedCount;

  bool get isLastQuestion => questions.isNotEmpty && currentIndex == questions.length - 1;

  ExamSimulatorState copyWith({
    ExamSimConfig? config,
    List<ExamSimQuestion>? questions,
    int? currentIndex,
    int? remainingSeconds,
    int? totalDurationSeconds,
    bool? isRunning,
    bool? isSubmitting,
    ExamSimResult? result,
  }) {
    return ExamSimulatorState(
      config: config ?? this.config,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      isRunning: isRunning ?? this.isRunning,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      result: result ?? this.result,
    );
  }
}

final examSimulatorControllerProvider =
    StateNotifierProvider<ExamSimulatorController, ExamSimulatorState>((ref) {
  final service = ref.watch(examSimulatorServiceProvider);
  return ExamSimulatorController(ref, service);
});

class ExamSimulatorController extends StateNotifier<ExamSimulatorState> {
  final Ref _ref;
  final ExamSimulatorService _service;
  Timer? _timer;

  ExamSimulatorController(this._ref, this._service)
      : super(const ExamSimulatorState());

  void initExam(ExamSimConfig config, List<ExamSimQuestion> questions) {
    _timer?.cancel();
    final totalSec = config.durationMinutes * 60;
    state = ExamSimulatorState(
      config: config,
      questions: questions,
      currentIndex: 0,
      remainingSeconds: totalSec,
      totalDurationSeconds: totalSec,
      isRunning: true,
      isSubmitting: false,
      result: null,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        // Track time spent on current question
        if (state.currentQuestion != null) {
          state.currentQuestion!.timeSpentSeconds++;
        }
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        // Time over, auto-submit
        _timer?.cancel();
        submitExam();
      }
    });
  }

  void selectOption(int optionIndex) {
    if (state.currentQuestion == null) return;
    final updated = List<ExamSimQuestion>.from(state.questions);
    final current = updated[state.currentIndex];
    updated[state.currentIndex] = current.copyWith(
      selectedOptionIndex: optionIndex,
    );
    state = state.copyWith(questions: updated);
  }

  void clearOption() {
    if (state.currentQuestion == null) return;
    final updated = List<ExamSimQuestion>.from(state.questions);
    final current = updated[state.currentIndex];
    // Copy with null selectedOptionIndex
    updated[state.currentIndex] = ExamSimQuestion(
      id: current.id,
      subject: current.subject,
      subtopic: current.subtopic,
      question: current.question,
      options: current.options,
      correctIndex: current.correctIndex,
      explanation: current.explanation,
      selectedOptionIndex: null,
      isMarkedForReview: current.isMarkedForReview,
      timeSpentSeconds: current.timeSpentSeconds,
    );
    state = state.copyWith(questions: updated);
  }

  void toggleMarkForReview() {
    if (state.currentQuestion == null) return;
    final updated = List<ExamSimQuestion>.from(state.questions);
    final current = updated[state.currentIndex];
    updated[state.currentIndex] = current.copyWith(
      isMarkedForReview: !current.isMarkedForReview,
    );
    state = state.copyWith(questions: updated);
  }

  void jumpToQuestion(int index) {
    if (index >= 0 && index < state.questions.length) {
      state = state.copyWith(currentIndex: index);
    }
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

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resumeTimer() {
    if (!state.isRunning && state.remainingSeconds > 0) {
      state = state.copyWith(isRunning: true);
      _startTimer();
    }
  }

  ExamSimResult submitExam({BuildContext? context}) {
    _timer?.cancel();
    final timeSpent = state.totalDurationSeconds - state.remainingSeconds;
    final result = _service.evaluateExam(
      config: state.config ?? const ExamSimConfig(title: 'Exam', subject: 'General'),
      questions: state.questions,
      totalTimeSpentSeconds: timeSpent,
    );

    state = state.copyWith(
      isRunning: false,
      isSubmitting: false,
      result: result,
    );

    // Award Scholar XP for taking exam
    _ref.read(gamificationControllerProvider.notifier).awardXp(
          amount: 50,
          reason: 'Mock Exam Completed 🎯',
          context: context,
        );

    // Bonus XP for score >= 80%
    if (result.percentage >= 80.0) {
      _ref.read(gamificationControllerProvider.notifier).awardXp(
            amount: 25,
            reason: 'High Distinction (>80%) 🌟',
            context: context,
          );
    }

    return result;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
