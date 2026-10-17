import 'sync_status.dart';

enum PomodoroMode {
  focus,
  shortBreak,
  longBreak;

  String get displayName {
    switch (this) {
      case PomodoroMode.focus:
        return 'Focus Session';
      case PomodoroMode.shortBreak:
        return 'Short Break';
      case PomodoroMode.longBreak:
        return 'Long Break';
    }
  }

  static PomodoroMode fromString(String? val) {
    return PomodoroMode.values.firstWhere(
      (e) => e.name == val,
      orElse: () => PomodoroMode.focus,
    );
  }
}

class PomodoroSessionModel {
  final String id;
  final String userId;
  final String subject;
  final int durationMinutes;
  final PomodoroMode mode;
  final DateTime completedAt;
  final SyncStatus syncStatus;

  PomodoroSessionModel({
    required this.id,
    required this.userId,
    required this.subject,
    required this.durationMinutes,
    required this.mode,
    required this.completedAt,
    this.syncStatus = SyncStatus.synced,
  });

  PomodoroSessionModel copyWith({
    String? id,
    String? userId,
    String? subject,
    int? durationMinutes,
    PomodoroMode? mode,
    DateTime? completedAt,
    SyncStatus? syncStatus,
  }) {
    return PomodoroSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      mode: mode ?? this.mode,
      completedAt: completedAt ?? this.completedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'subject': subject,
      'durationMinutes': durationMinutes,
      'mode': mode.name,
      'completedAt': completedAt.toIso8601String(),
      'syncStatus': syncStatus.toDbString(),
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'userId': userId,
      'subject': subject,
      'durationMinutes': durationMinutes,
      'mode': mode.name,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory PomodoroSessionModel.fromMap(Map<String, dynamic> map) {
    return PomodoroSessionModel(
      id: map['id'] as String,
      userId: (map['userId'] as String?) ?? '',
      subject: (map['subject'] as String?) ?? 'General',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 25,
      mode: PomodoroMode.fromString(map['mode'] as String?),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : DateTime.now(),
      syncStatus: SyncStatus.fromDbString(map['syncStatus'] as String?),
    );
  }
}
