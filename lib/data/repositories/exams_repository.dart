import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/app_database.dart';
import '../local/notification_service.dart';
import '../models/exam_model.dart';
import '../models/sync_status.dart';
import '../remote/firebase_service.dart';

final examsRepositoryProvider = Provider<ExamsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return ExamsRepository(db, firebaseService, notificationService);
});

class ExamsRepository {
  final AppDatabase _db;
  final FirebaseService _firebaseService;
  final NotificationService _notificationService;

  ExamsRepository(this._db, this._firebaseService, this._notificationService);

  Future<List<ExamModel>> getExams(String userId) async {
    final localExams = await _db.getExams(userId);

    if (_firebaseService.isConfigured && userId.isNotEmpty) {
      _syncFromRemote(userId).catchError((e) {
        debugPrint('Exams remote sync notice: $e');
        return <ExamModel>[];
      });
    }

    return localExams;
  }

  Future<void> saveExam(ExamModel exam) async {
    await _db.insertExam(exam);

    if (exam.reminderEnabled &&
        !exam.isCompleted &&
        exam.examDate.isAfter(DateTime.now())) {
      final notifId = exam.id.hashCode.abs();
      _notificationService.showNotification(
        id: notifId,
        title: 'Exam Alert: ${exam.title} (${exam.subject})',
        body:
            'Scheduled on ${exam.examDate.day}/${exam.examDate.month}/${exam.examDate.year}',
      );
    } else {
      _notificationService.cancelNotification(exam.id.hashCode.abs());
    }

    if (_firebaseService.isConfigured && exam.userId.isNotEmpty) {
      try {
        final col = _firebaseService.getUserCollection(exam.userId, 'exams');
        if (col != null) {
          await col.doc(exam.id).set(exam.toFirestoreMap());
          await _db.updateExam(exam.copyWith(syncStatus: SyncStatus.synced));
        }
      } catch (e) {
        debugPrint('Firestore exam upload warning: $e');
        await _db.updateExam(exam.copyWith(syncStatus: SyncStatus.pendingSync));
      }
    }
  }

  Future<void> deleteExam(String id, String userId) async {
    await _db.deleteExam(id);
    _notificationService.cancelNotification(id.hashCode.abs());

    if (_firebaseService.isConfigured && userId.isNotEmpty) {
      try {
        final col = _firebaseService.getUserCollection(userId, 'exams');
        if (col != null) {
          await col.doc(id).delete();
        }
      } catch (e) {
        debugPrint('Firestore exam delete warning: $e');
      }
    }
  }

  Future<List<ExamModel>> _syncFromRemote(String userId) async {
    final col = _firebaseService.getUserCollection(userId, 'exams');
    if (col == null) return [];

    final snapshot = await col.get();
    final remoteExams = snapshot.docs
        .map((doc) => ExamModel.fromMap(doc.data()))
        .toList();

    for (final exam in remoteExams) {
      await _db.insertExam(exam.copyWith(syncStatus: SyncStatus.synced));
    }
    return remoteExams;
  }
}
