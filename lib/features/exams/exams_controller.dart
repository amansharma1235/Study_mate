import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/exam_model.dart';
import '../../data/repositories/exams_repository.dart';
import '../auth/auth_controller.dart';

final examsControllerProvider =
    StateNotifierProvider<ExamsController, AsyncValue<List<ExamModel>>>((ref) {
      final repo = ref.watch(examsRepositoryProvider);
      final user = ref.watch(currentProfileProvider);
      final userId = user?.uid ?? 'guest';
      return ExamsController(repo, userId);
    });

final upcomingExamsProvider = Provider<List<ExamModel>>((ref) {
  final examsState = ref.watch(examsControllerProvider);
  return examsState.maybeWhen(
    data: (exams) {
      final now = DateTime.now();
      final upcoming = exams
          .where((e) => !e.isCompleted && e.examDate.isAfter(now))
          .toList();
      upcoming.sort((a, b) => a.examDate.compareTo(b.examDate));
      return upcoming;
    },
    orElse: () => [],
  );
});

class ExamsController extends StateNotifier<AsyncValue<List<ExamModel>>> {
  final ExamsRepository _repo;
  final String _userId;

  ExamsController(this._repo, this._userId)
    : super(const AsyncValue.loading()) {
    loadExams();
  }

  Future<void> loadExams() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => await _repo.getExams(_userId));
  }

  Future<void> addExam({
    required String title,
    required String subject,
    required DateTime examDate,
    String description = '',
    bool reminderEnabled = true,
  }) async {
    final newExam = ExamModel(
      id: const Uuid().v4(),
      userId: _userId,
      title: title.trim(),
      subject: subject.trim(),
      examDate: examDate,
      description: description.trim(),
      reminderEnabled: reminderEnabled,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repo.saveExam(newExam);
    await loadExams();
  }

  Future<void> updateExam(ExamModel exam) async {
    final updated = exam.copyWith(updatedAt: DateTime.now());
    await _repo.saveExam(updated);
    await loadExams();
  }

  Future<void> toggleCompleted(ExamModel exam) async {
    final updated = exam.copyWith(
      isCompleted: !exam.isCompleted,
      updatedAt: DateTime.now(),
    );
    await _repo.saveExam(updated);
    await loadExams();
  }

  Future<void> deleteExam(String id) async {
    await _repo.deleteExam(id, _userId);
    await loadExams();
  }
}
