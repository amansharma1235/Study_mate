import 'sync_status.dart';

class SyllabusTopicModel {
  final String id;
  final String userId;
  final String subject;
  final String chapter;
  final String title;
  final String status; // 'not_started', 'in_progress', 'completed'
  final String difficulty; // 'easy', 'medium', 'hard'
  final String priority; // 'low', 'medium', 'high'
  final int revisionCount;
  final DateTime? lastRevisionDate;
  final DateTime? nextRevisionDate;
  final String notes;
  final SyncStatus syncStatus;

  SyllabusTopicModel({
    required this.id,
    required this.userId,
    required this.subject,
    required this.chapter,
    required this.title,
    this.status = 'not_started',
    this.difficulty = 'medium',
    this.priority = 'medium',
    this.revisionCount = 0,
    this.lastRevisionDate,
    this.nextRevisionDate,
    this.notes = '',
    this.syncStatus = SyncStatus.synced,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'subject': subject,
      'chapter': chapter,
      'title': title,
      'status': status,
      'difficulty': difficulty,
      'priority': priority,
      'revisionCount': revisionCount,
      'lastRevisionDate': lastRevisionDate?.toIso8601String(),
      'nextRevisionDate': nextRevisionDate?.toIso8601String(),
      'notes': notes,
      'syncStatus': syncStatus.name,
    };
  }

  factory SyllabusTopicModel.fromMap(Map<String, dynamic> map) {
    return SyllabusTopicModel(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      subject: map['subject'] as String? ?? 'General',
      chapter: map['chapter'] as String? ?? 'General',
      title: map['title'] as String? ?? '',
      status: map['status'] as String? ?? 'not_started',
      difficulty: map['difficulty'] as String? ?? 'medium',
      priority: map['priority'] as String? ?? 'medium',
      revisionCount: map['revisionCount'] as int? ?? 0,
      lastRevisionDate: map['lastRevisionDate'] != null
          ? DateTime.tryParse(map['lastRevisionDate'] as String)
          : null,
      nextRevisionDate: map['nextRevisionDate'] != null
          ? DateTime.tryParse(map['nextRevisionDate'] as String)
          : null,
      notes: map['notes'] as String? ?? '',
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == map['syncStatus'],
        orElse: () => SyncStatus.synced,
      ),
    );
  }

  SyllabusTopicModel copyWith({
    String? id,
    String? userId,
    String? subject,
    String? chapter,
    String? title,
    String? status,
    String? difficulty,
    String? priority,
    int? revisionCount,
    DateTime? lastRevisionDate,
    DateTime? nextRevisionDate,
    String? notes,
    SyncStatus? syncStatus,
  }) {
    return SyllabusTopicModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      chapter: chapter ?? this.chapter,
      title: title ?? this.title,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      priority: priority ?? this.priority,
      revisionCount: revisionCount ?? this.revisionCount,
      lastRevisionDate: lastRevisionDate ?? this.lastRevisionDate,
      nextRevisionDate: nextRevisionDate ?? this.nextRevisionDate,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
