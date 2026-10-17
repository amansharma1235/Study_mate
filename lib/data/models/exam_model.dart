import 'sync_status.dart';

class ExamModel {
  final String id;
  final String userId;
  final String title;
  final String subject;
  final DateTime examDate;
  final String description;
  final bool reminderEnabled;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;

  ExamModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.subject,
    required this.examDate,
    this.description = '',
    this.reminderEnabled = true,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.synced,
  });

  bool get isPast => examDate.isBefore(DateTime.now());

  ExamModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? subject,
    DateTime? examDate,
    String? description,
    bool? reminderEnabled,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) {
    return ExamModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      examDate: examDate ?? this.examDate,
      description: description ?? this.description,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'subject': subject,
      'examDate': examDate.toIso8601String(),
      'description': description,
      'reminderEnabled': reminderEnabled ? 1 : 0,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': syncStatus.toDbString(),
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'subject': subject,
      'examDate': examDate.toIso8601String(),
      'description': description,
      'reminderEnabled': reminderEnabled,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ExamModel.fromMap(Map<String, dynamic> map) {
    return ExamModel(
      id: map['id'] as String,
      userId: (map['userId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      subject: (map['subject'] as String?) ?? '',
      examDate: map['examDate'] != null
          ? DateTime.parse(map['examDate'] as String)
          : DateTime.now(),
      description: (map['description'] as String?) ?? '',
      reminderEnabled:
          map['reminderEnabled'] == 1 || map['reminderEnabled'] == true,
      isCompleted: map['isCompleted'] == 1 || map['isCompleted'] == true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      syncStatus: SyncStatus.fromDbString(map['syncStatus'] as String?),
    );
  }
}
