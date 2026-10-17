import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';
import '../../data/models/syllabus_model.dart';
import '../auth/auth_controller.dart';

final syllabusTopicsProvider =
    StateNotifierProvider<
      SyllabusController,
      AsyncValue<List<SyllabusTopicModel>>
    >((ref) {
      final db = ref.watch(appDatabaseProvider);
      final user = ref.watch(currentProfileProvider);
      final userId = user?.uid ?? 'guest';
      return SyllabusController(db, userId);
    });

final syllabusSubjectFilterProvider = StateProvider<String>((ref) => 'All');

final filteredSyllabusTopicsProvider = Provider<List<SyllabusTopicModel>>((
  ref,
) {
  final topicsAsync = ref.watch(syllabusTopicsProvider);
  final filter = ref.watch(syllabusSubjectFilterProvider);

  return topicsAsync.maybeWhen(
    data: (topics) {
      if (filter == 'All') return topics;
      return topics.where((t) => t.subject == filter).toList();
    },
    orElse: () => [],
  );
});

class SyllabusController
    extends StateNotifier<AsyncValue<List<SyllabusTopicModel>>> {
  final AppDatabase _db;
  final String _userId;

  SyllabusController(this._db, this._userId)
    : super(const AsyncValue.loading()) {
    loadTopics();
  }

  Future<void> loadTopics() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () async => await _db.getSyllabusTopics(_userId),
    );
  }

  Future<void> addTopic({
    required String subject,
    required String chapter,
    required String title,
    String status = 'not_started',
    String difficulty = 'medium',
    String priority = 'medium',
    String notes = '',
  }) async {
    final topic = SyllabusTopicModel(
      id: const Uuid().v4(),
      userId: _userId,
      subject: subject,
      chapter: chapter,
      title: title,
      status: status,
      difficulty: difficulty,
      priority: priority,
      notes: notes,
    );

    await _db.insertSyllabusTopic(topic);
    await loadTopics();
  }

  Future<void> updateStatus(SyllabusTopicModel topic, String newStatus) async {
    final updated = topic.copyWith(status: newStatus);
    await _db.updateSyllabusTopic(updated);
    await loadTopics();
  }

  Future<void> markRevised(SyllabusTopicModel topic) async {
    final now = DateTime.now();
    // Schedule next revision in 7 days
    final nextRev = now.add(const Duration(days: 7));
    final updated = topic.copyWith(
      revisionCount: topic.revisionCount + 1,
      lastRevisionDate: now,
      nextRevisionDate: nextRev,
      status: 'completed',
    );
    await _db.updateSyllabusTopic(updated);
    await loadTopics();
  }

  Future<void> deleteTopic(String id) async {
    await _db.deleteSyllabusTopic(id);
    await loadTopics();
  }

  Future<void> seedStarterSyllabus() async {
    final sample = [
      {
        'subject': 'Mathematics',
        'chapter': 'Differential Calculus',
        'title': 'Limits, Continuity & Differentiability',
        'status': 'completed',
        'diff': 'medium',
        'pri': 'high',
      },
      {
        'subject': 'Mathematics',
        'chapter': 'Differential Calculus',
        'title': 'Mean Value Theorems & Chain Rule',
        'status': 'in_progress',
        'diff': 'hard',
        'pri': 'high',
      },
      {
        'subject': 'Mathematics',
        'chapter': 'Integral Calculus',
        'title': 'Definite Integrals & Area Under Curves',
        'status': 'not_started',
        'diff': 'hard',
        'pri': 'high',
      },
      {
        'subject': 'Computer Science',
        'chapter': 'Data Structures',
        'title': 'Arrays, Linked Lists & Doubly Linked Lists',
        'status': 'completed',
        'diff': 'easy',
        'pri': 'high',
      },
      {
        'subject': 'Computer Science',
        'chapter': 'Data Structures',
        'title': 'Stack & Queue Applications in Compilers',
        'status': 'in_progress',
        'diff': 'medium',
        'pri': 'medium',
      },
      {
        'subject': 'Computer Science',
        'chapter': 'Algorithms',
        'title': 'Dynamic Programming - 0/1 Knapsack & LCS',
        'status': 'not_started',
        'diff': 'hard',
        'pri': 'high',
      },
      {
        'subject': 'Physics',
        'chapter': 'Electrostatics',
        'title': 'Coulomb\'s Law, Electric Fields & Flux',
        'status': 'completed',
        'diff': 'medium',
        'pri': 'high',
      },
      {
        'subject': 'Physics',
        'chapter': 'Current Electricity',
        'title': 'Kirchhoff\'s Laws & Wheatstone Bridge',
        'status': 'not_started',
        'diff': 'medium',
        'pri': 'medium',
      },
    ];

    for (final item in sample) {
      await addTopic(
        subject: item['subject'] as String,
        chapter: item['chapter'] as String,
        title: item['title'] as String,
        status: item['status'] as String,
        difficulty: item['diff'] as String,
        priority: item['pri'] as String,
      );
    }
  }
}
