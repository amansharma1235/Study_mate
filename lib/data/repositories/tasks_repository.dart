import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/notification_service.dart';
import '../models/sync_status.dart';
import '../models/task_model.dart';
import '../remote/firebase_service.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return TasksRepository(firebaseService, notificationService);
});

/// Pure Cloud-First Tasks Repository.
/// All user tasks are synced directly to and from Cloud Firestore (users/{userId}/tasks).
/// In-memory state is maintained temporarily during execution.
/// No tasks are persisted locally in SQLite or local files.
class TasksRepository {
  final FirebaseService _firebaseService;
  final NotificationService _notificationService;
  final Map<String, List<TaskModel>> _sessionCache = {};

  TasksRepository(this._firebaseService, this._notificationService);

  Future<List<TaskModel>> getTasks(String userId) async {
    if (userId.isEmpty) return [];

    if (_firebaseService.isConfigured && userId != 'guest') {
      try {
        final col = _firebaseService.getUserCollection(userId, 'tasks');
        if (col != null) {
          final snapshot = await col.orderBy('dueDate', descending: false).get();
          final tasks = snapshot.docs
              .map((doc) => TaskModel.fromMap(doc.data()))
              .toList();
          _sessionCache[userId] = tasks;
          return tasks;
        }
      } catch (e) {
        debugPrint('Cloud tasks fetch notice: $e');
        return _sessionCache[userId] ?? [];
      }
    }

    return _sessionCache[userId] ?? [];
  }

  Future<void> saveTask(TaskModel task) async {
    final taskWithSync = task.copyWith(syncStatus: SyncStatus.synced);

    final list = _sessionCache[task.userId] ?? [];
    final index = list.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      list[index] = taskWithSync;
    } else {
      list.add(taskWithSync);
    }
    _sessionCache[task.userId] = list;

    // Ephemeral OS notification reminder
    if (task.reminderEnabled &&
        !task.isCompleted &&
        task.dueDate.isAfter(DateTime.now())) {
      final notifId = task.id.hashCode.abs();
      _notificationService.showNotification(
        id: notifId,
        title: 'Task Reminder: ${task.title}',
        body:
            'Due on ${task.dueDate.hour}:${task.dueDate.minute.toString().padLeft(2, '0')}',
      );
    } else {
      _notificationService.cancelNotification(task.id.hashCode.abs());
    }

    if (_firebaseService.isConfigured && task.userId.isNotEmpty && task.userId != 'guest') {
      final col = _firebaseService.getUserCollection(task.userId, 'tasks');
      if (col != null) {
        await col.doc(task.id).set(taskWithSync.toFirestoreMap());
      }
    }
  }

  Future<void> toggleTask(TaskModel task) async {
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
    );
    await saveTask(updated);
  }

  Future<void> deleteTask(String id, String userId) async {
    if (_sessionCache.containsKey(userId)) {
      _sessionCache[userId]!.removeWhere((t) => t.id == id);
    }
    _notificationService.cancelNotification(id.hashCode.abs());

    if (_firebaseService.isConfigured && userId.isNotEmpty && userId != 'guest') {
      final col = _firebaseService.getUserCollection(userId, 'tasks');
      if (col != null) {
        await col.doc(id).delete();
      }
    }
  }
}
