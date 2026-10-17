import 'sync_status.dart';

class NoteModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String category;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;

  NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.category = 'General',
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.synced,
  });

  NoteModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? category,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) {
    return NoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
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
      'content': content,
      'category': category,
      'isPinned': isPinned ? 1 : 0,
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
      'content': content,
      'category': category,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as String,
      userId: (map['userId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'General',
      isPinned: map['isPinned'] == 1 || map['isPinned'] == true,
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
