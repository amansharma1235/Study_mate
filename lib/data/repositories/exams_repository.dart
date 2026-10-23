import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/notification_service.dart';
import '../models/exam_model.dart';
import '../models/sync_status.dart';
import '../remote/firebase_service.dart';

final examsRepositoryProvider = Provider<ExamsRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return ExamsRepository(firebaseService, notificationService);
});

/// Pure Cloud-First Exams Repository.
/// All exams and countdown data are stored in Cloud Firestore (users/{userId}/exams).
/// In-memory state is maintained temporarily during execution.
/// No exam records are persisted locally in SQLite or local files.
class ExamsRepository {
  final FirebaseService _firebaseService;
  final NotificationService _notificationService;
  final Map<String, List<ExamModel>> _sessionCache = {};

  ExamsRepository(this._firebaseService, this._notificationService);

  Future<List<ExamModel>> getExams(String userId) async {
    if (userId.isEmpty) return [];

    if (_firebaseService.isConfigured && userId != 'guest') {
      try {
        final col = _firebaseService.getUserCollection(userId, 'exams');
        if (col != null) {
          final snapshot = await col.orderBy('examDate', descending: false).get();
          final exams = snapshot.docs
              .map((doc) => ExamModel.fromMap(doc.data()))
              .toList();
          _sessionCache[userId] = exams;
          return exams;
        }
      } catch (e) {
        debugPrint('Cloud exams fetch notice: $e');
        return _sessionCache[userId] ?? [];
      }
    }

    return _sessionCache[userId] ?? [];
  }

  Future<void> saveExam(ExamModel exam) async {
    final examWithSync = exam.copyWith(syncStatus: SyncStatus.synced);

    final list = _sessionCache[exam.userId] ?? [];
    final index = list.indexWhere((e) => e.id == exam.id);
    if (index >= 0) {
      list[index] = examWithSync;
    } else {
      list.add(examWithSync);
    }
    _sessionCache[exam.userId] = list;

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

    if (_firebaseService.isConfigured && exam.userId.isNotEmpty && exam.userId != 'guest') {
      final col = _firebaseService.getUserCollection(exam.userId, 'exams');
      if (col != null) {
        await col.doc(exam.id).set(examWithSync.toFirestoreMap());
      }
    }
  }

  Future<void> deleteExam(String id, String userId) async {
    if (_sessionCache.containsKey(userId)) {
      _sessionCache[userId]!.removeWhere((e) => e.id == id);
    }
    _notificationService.cancelNotification(id.hashCode.abs());

    if (_firebaseService.isConfigured && userId.isNotEmpty && userId != 'guest') {
      final col = _firebaseService.getUserCollection(userId, 'exams');
      if (col != null) {
        await col.doc(id).delete();
      }
    }
  }
}
