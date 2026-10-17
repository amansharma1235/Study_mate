import 'sync_status.dart';

class StudySessionModel {
  final String id;
  final String userId;
  final String subject;
  final String topic;
  final DateTime sessionDate;
  final String startTime; // "09:00"
  final String endTime; // "10:30"
  final int durationMinutes;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String difficulty; // 'easy', 'medium', 'hard'
  final bool isCompleted;
  final bool isBreak;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;

  StudySessionModel({
    required this.id,
    required this.userId,
    required this.subject,
    required this.topic,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.priority = 'medium',
    this.difficulty = 'medium',
    this.isCompleted = false,
    this.isBreak = false,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = SyncStatus.synced,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'subject': subject,
      'topic': topic,
      'sessionDate': sessionDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'durationMinutes': durationMinutes,
      'priority': priority,
      'difficulty': difficulty,
      'isCompleted': isCompleted ? 1 : 0,
      'isBreak': isBreak ? 1 : 0,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': syncStatus.name,
    };
  }

  factory StudySessionModel.fromMap(Map<String, dynamic> map) {
    return StudySessionModel(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      subject: map['subject'] as String? ?? 'General',
      topic: map['topic'] as String? ?? '',
      sessionDate:
          DateTime.tryParse(map['sessionDate'] as String? ?? '') ??
          DateTime.now(),
      startTime: map['startTime'] as String? ?? '09:00',
      endTime: map['endTime'] as String? ?? '10:00',
      durationMinutes: map['durationMinutes'] as int? ?? 60,
      priority: map['priority'] as String? ?? 'medium',
      difficulty: map['difficulty'] as String? ?? 'medium',
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      isBreak: (map['isBreak'] as int? ?? 0) == 1,
      notes: map['notes'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == map['syncStatus'],
        orElse: () => SyncStatus.synced,
      ),
    );
  }

  StudySessionModel copyWith({
    String? id,
    String? userId,
    String? subject,
    String? topic,
    DateTime? sessionDate,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    String? priority,
    String? difficulty,
    bool? isCompleted,
    bool? isBreak,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) {
    return StudySessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      sessionDate: sessionDate ?? this.sessionDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      priority: priority ?? this.priority,
      difficulty: difficulty ?? this.difficulty,
      isCompleted: isCompleted ?? this.isCompleted,
      isBreak: isBreak ?? this.isBreak,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  // Conflict detection helper
  static bool hasTimeConflict(StudySessionModel a, StudySessionModel b) {
    if (a.id == b.id) return false;
    // Must be on the exact same date
    if (a.sessionDate.year != b.sessionDate.year ||
        a.sessionDate.month != b.sessionDate.month ||
        a.sessionDate.day != b.sessionDate.day) {
      return false;
    }

    final aStart = _timeToMinutes(a.startTime);
    final aEnd = _timeToMinutes(a.endTime);
    final bStart = _timeToMinutes(b.startTime);
    final bEnd = _timeToMinutes(b.endTime);

    return aStart < bEnd && bStart < aEnd;
  }

  static int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return (h * 60) + m;
  }
}
