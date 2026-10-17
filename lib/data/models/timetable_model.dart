import 'sync_status.dart';

class TimetableModel {
  final String id;
  final String userId;
  final String subject;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final String startTime; // "HH:mm" (24-hour)
  final String endTime; // "HH:mm" (24-hour)
  final String room;
  final String instructor;
  final String colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;

  TimetableModel({
    required this.id,
    required this.userId,
    required this.subject,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room = '',
    this.instructor = '',
    this.colorHex = '#6258E8',
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.synced,
  });

  // Calculate start minutes from midnight
  int get startMinutes {
    final parts = startTime.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // Calculate end minutes from midnight
  int get endMinutes {
    final parts = endTime.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  bool hasConflictWith(TimetableModel other) {
    if (dayOfWeek != other.dayOfWeek || id == other.id) return false;
    return startMinutes < other.endMinutes && endMinutes > other.startMinutes;
  }

  TimetableModel copyWith({
    String? id,
    String? userId,
    String? subject,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? room,
    String? instructor,
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) {
    return TimetableModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      instructor: instructor ?? this.instructor,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'subject': subject,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'instructor': instructor,
      'colorHex': colorHex,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': syncStatus.toDbString(),
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'userId': userId,
      'subject': subject,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'instructor': instructor,
      'colorHex': colorHex,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TimetableModel.fromMap(Map<String, dynamic> map) {
    return TimetableModel(
      id: map['id'] as String,
      userId: (map['userId'] as String?) ?? '',
      subject: (map['subject'] as String?) ?? '',
      dayOfWeek: (map['dayOfWeek'] as num?)?.toInt() ?? 1,
      startTime: (map['startTime'] as String?) ?? '09:00',
      endTime: (map['endTime'] as String?) ?? '10:00',
      room: (map['room'] as String?) ?? '',
      instructor: (map['instructor'] as String?) ?? '',
      colorHex: (map['colorHex'] as String?) ?? '#6258E8',
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
