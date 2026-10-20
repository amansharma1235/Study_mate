import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/task_model.dart';
import '../../data/repositories/tasks_repository.dart';
import '../auth/auth_controller.dart';
import '../gamification/gamification_controller.dart';

enum TaskFilter { today, upcoming, completed, all }

final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);
final taskSearchQueryProvider = StateProvider<String>((ref) => '');

final tasksControllerProvider =
    StateNotifierProvider<TasksController, AsyncValue<List<TaskModel>>>((ref) {
      final repo = ref.watch(tasksRepositoryProvider);
      final user = ref.watch(currentProfileProvider);
      final userId = user?.uid ?? 'guest';
      return TasksController(repo, userId, ref: ref);
    });

final filteredTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasksState = ref.watch(tasksControllerProvider);
  final filter = ref.watch(taskFilterProvider);
  final query = ref.watch(taskSearchQueryProvider).toLowerCase();

  return tasksState.maybeWhen(
    data: (tasks) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      return tasks.where((t) {
        // Query match
        final matchesQuery =
            query.isEmpty ||
            t.title.toLowerCase().contains(query) ||
            t.subject.toLowerCase().contains(query);
        if (!matchesQuery) return false;

        // Filter match
        switch (filter) {
          case TaskFilter.today:
            return !t.isCompleted &&
                t.dueDate.isAfter(todayStart) &&
                t.dueDate.isBefore(todayEnd);
          case TaskFilter.upcoming:
            return !t.isCompleted && t.dueDate.isAfter(todayEnd);
          case TaskFilter.completed:
            return t.isCompleted;
          case TaskFilter.all:
            return true;
        }
      }).toList();
    },
    orElse: () => [],
  );
});

class TasksController extends StateNotifier<AsyncValue<List<TaskModel>>> {
  final TasksRepository _repo;
  final String _userId;
  final Ref? ref;

  TasksController(this._repo, this._userId, {this.ref})
      : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async => await _repo.getTasks(_userId));
  }

  Future<void> addTask({
    required String title,
    String description = '',
    required DateTime dueDate,
    TaskPriority priority = TaskPriority.medium,
    String subject = 'General',
    bool reminderEnabled = false,
  }) async {
    final newTask = TaskModel(
      id: const Uuid().v4(),
      userId: _userId,
      title: title.trim(),
      description: description.trim(),
      dueDate: dueDate,
      priority: priority,
      subject: subject.trim(),
      reminderEnabled: reminderEnabled,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repo.saveTask(newTask);
    await loadTasks();
  }

  Future<void> updateTask(TaskModel task) async {
    final updated = task.copyWith(updatedAt: DateTime.now());
    await _repo.saveTask(updated);
    await loadTasks();
  }

  Future<void> toggleTask(TaskModel task) async {
    final willComplete = !task.isCompleted;
    await _repo.toggleTask(task);
    if (willComplete) {
      ref?.read(gamificationControllerProvider.notifier).recordTaskCompleted();
    }
    await loadTasks();
  }

  Future<void> deleteTask(String id) async {
    await _repo.deleteTask(id, _userId);
    await loadTasks();
  }
}
