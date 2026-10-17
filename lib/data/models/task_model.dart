import 'sync_status.dart';

enum TaskPriority {
  low,
  medium,
  high;

  static TaskPriority fromString(String? val) {
    return TaskPriority.values.firstWhere(
      (e) => e.name == val?.toLowerCase(),
      orElse: () => TaskPriority.medium,
    );
  }
}

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  final String subject;
  final bool isCompleted;
  final bool reminderEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.priority = TaskPriority.medium,
    this.subject = 'General',
    this.isCompleted = false,
    this.reminderEnabled = false,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.synced,
  });

  bool get isOverdue => !isCompleted && dueDate.isBefore(DateTime.now());

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    String? subject,
    bool? isCompleted,
    bool? reminderEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      subject: subject ?? this.subject,
      isCompleted: isCompleted ?? this.isCompleted,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
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
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.name,
      'subject': subject,
      'isCompleted': isCompleted ? 1 : 0,
      'reminderEnabled': reminderEnabled ? 1 : 0,
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
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.name,
      'subject': subject,
      'isCompleted': isCompleted,
      'reminderEnabled': reminderEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      userId: (map['userId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : DateTime.now(),
      priority: TaskPriority.fromString(map['priority'] as String?),
      subject: (map['subject'] as String?) ?? 'General',
      isCompleted: map['isCompleted'] == 1 || map['isCompleted'] == true,
      reminderEnabled:
          map['reminderEnabled'] == 1 || map['reminderEnabled'] == true,
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
