import 'sync_status.dart';

class StudyGroupModel {
  final String id;
  final String name;
  final String description;
  final String subject;
  final String adminUserId;
  final String joinCode;
  final int memberCount;
  final int sharedNotesCount;
  final DateTime createdAt;
  final SyncStatus syncStatus;

  StudyGroupModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.subject,
    required this.adminUserId,
    required this.joinCode,
    this.memberCount = 1,
    this.sharedNotesCount = 0,
    DateTime? createdAt,
    this.syncStatus = SyncStatus.synced,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subject': subject,
      'adminUserId': adminUserId,
      'joinCode': joinCode,
      'memberCount': memberCount,
      'sharedNotesCount': sharedNotesCount,
      'createdAt': createdAt.toIso8601String(),
      'syncStatus': syncStatus.name,
    };
  }

  factory StudyGroupModel.fromMap(Map<String, dynamic> map) {
    return StudyGroupModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      subject: map['subject'] as String? ?? 'General',
      adminUserId: map['adminUserId'] as String? ?? '',
      joinCode: map['joinCode'] as String? ?? '',
      memberCount: map['memberCount'] as int? ?? 1,
      sharedNotesCount: map['sharedNotesCount'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == map['syncStatus'],
        orElse: () => SyncStatus.synced,
      ),
    );
  }
}
