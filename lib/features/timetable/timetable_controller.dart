import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/timetable_model.dart';
import '../../data/repositories/timetable_repository.dart';
import '../auth/auth_controller.dart';

final selectedTimetableDayProvider = StateProvider<int>(
  (ref) => DateTime.now().weekday,
);

final timetableControllerProvider =
    StateNotifierProvider<
      TimetableController,
      AsyncValue<List<TimetableModel>>
    >((ref) {
      final repo = ref.watch(timetableRepositoryProvider);
      final user = ref.watch(currentProfileProvider);
      final userId = user?.uid ?? 'guest';
      return TimetableController(repo, userId);
    });

final currentDayClassesProvider = Provider<List<TimetableModel>>((ref) {
  final state = ref.watch(timetableControllerProvider);
  final day = ref.watch(selectedTimetableDayProvider);

  return state.maybeWhen(
    data: (classes) {
      final list = classes.where((c) => c.dayOfWeek == day).toList();
      list.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
      return list;
    },
    orElse: () => [],
  );
});

class TimetableController
    extends StateNotifier<AsyncValue<List<TimetableModel>>> {
  final TimetableRepository _repo;
  final String _userId;

  TimetableController(this._repo, this._userId)
    : super(const AsyncValue.loading()) {
    loadTimetable();
  }

  Future<void> loadTimetable() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () async => await _repo.getTimetable(_userId),
    );
  }

  bool hasConflict(TimetableModel candidate) {
    return state.maybeWhen(
      data: (list) {
        return list.any((existing) => existing.hasConflictWith(candidate));
      },
      orElse: () => false,
    );
  }

  Future<bool> addClass({
    required String subject,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String room = '',
    String instructor = '',
    String colorHex = '#6258E8',
  }) async {
    final newEntry = TimetableModel(
      id: const Uuid().v4(),
      userId: _userId,
      subject: subject.trim(),
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      room: room.trim(),
      instructor: instructor.trim(),
      colorHex: colorHex,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (hasConflict(newEntry)) {
      return false; // Conflict detected
    }

    await _repo.saveTimetable(newEntry);
    await loadTimetable();
    return true;
  }

  Future<bool> updateClass(TimetableModel entry) async {
    if (hasConflict(entry)) {
      return false;
    }
    final updated = entry.copyWith(updatedAt: DateTime.now());
    await _repo.saveTimetable(updated);
    await loadTimetable();
    return true;
  }

  Future<void> deleteClass(String id) async {
    await _repo.deleteTimetable(id, _userId);
    await loadTimetable();
  }
}
