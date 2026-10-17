import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_database.dart';
import '../local/notification_service.dart';
import '../models/sync_status.dart';
import '../models/task_model.dart';
import '../remote/firebase_service.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return TasksRepository(db, firebaseService, notificationService);
});

class TasksRepository {
  final AppDatabase _db;
  final FirebaseService _firebaseService;
  final NotificationService _notificationService;

  TasksRepository(this._db, this._firebaseService, this._notificationService);

  Future<List<TaskModel>> getTasks(String userId) async {
    final localTasks = await _db.getTasks(userId);

    if (_firebaseService.isConfigured && userId.isNotEmpty) {
      _syncFromRemote(userId).catchError((e) {
        debugPrint('Tasks remote sync notice: $e');
        return <TaskModel>[];
      });
    }

    return localTasks;
  }

  Future<void> saveTask(TaskModel task) async {
    await _db.insertTask(task);

    // Schedule local reminder if enabled and in the future
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

    if (_firebaseService.isConfigured && task.userId.isNotEmpty) {
      try {
        final col = _firebaseService.getUserCollection(task.userId, 'tasks');
        if (col != null) {
          await col.doc(task.id).set(task.toFirestoreMap());
          await _db.updateTask(task.copyWith(syncStatus: SyncStatus.synced));
        }
      } catch (e) {
        debugPrint('Firestore task upload warning: $e');
        await _db.updateTask(task.copyWith(syncStatus: SyncStatus.pendingSync));
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
    await _db.deleteTask(id);
    _notificationService.cancelNotification(id.hashCode.abs());

    if (_firebaseService.isConfigured && userId.isNotEmpty) {
      try {
        final col = _firebaseService.getUserCollection(userId, 'tasks');
        if (col != null) {
          await col.doc(id).delete();
        }
      } catch (e) {
        debugPrint('Firestore task delete warning: $e');
      }
    }
  }

  Future<List<TaskModel>> _syncFromRemote(String userId) async {
    final col = _firebaseService.getUserCollection(userId, 'tasks');
    if (col == null) return [];

    final snapshot = await col.get();
    final remoteTasks = snapshot.docs
        .map((doc) => TaskModel.fromMap(doc.data()))
        .toList();

    for (final task in remoteTasks) {
      await _db.insertTask(task.copyWith(syncStatus: SyncStatus.synced));
    }
    return remoteTasks;
  }
}
