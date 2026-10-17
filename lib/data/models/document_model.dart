import 'sync_status.dart';

class DocumentModel {
  final String id;
  final String userId;
  final String title;
  final String subject;
  final String fileType; // 'pdf', 'notes', 'doc', 'image'
  final String filePath;
  final int fileSizeBytes;
  final int pageCount;
  final int lastOpenedPage;
  final bool isBookmarked;
  final DateTime createdAt;
  final SyncStatus syncStatus;

  DocumentModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.subject,
    this.fileType = 'pdf',
    required this.filePath,
    this.fileSizeBytes = 0,
    this.pageCount = 1,
    this.lastOpenedPage = 1,
    this.isBookmarked = false,
    DateTime? createdAt,
    this.syncStatus = SyncStatus.synced,
  }) : createdAt = createdAt ?? DateTime.now();

  String get formattedSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    }
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'subject': subject,
      'fileType': fileType,
      'filePath': filePath,
      'fileSizeBytes': fileSizeBytes,
      'pageCount': pageCount,
      'lastOpenedPage': lastOpenedPage,
      'isBookmarked': isBookmarked ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'syncStatus': syncStatus.name,
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subject: map['subject'] as String? ?? 'General',
      fileType: map['fileType'] as String? ?? 'pdf',
      filePath: map['filePath'] as String? ?? '',
      fileSizeBytes: map['fileSizeBytes'] as int? ?? 0,
      pageCount: map['pageCount'] as int? ?? 1,
      lastOpenedPage: map['lastOpenedPage'] as int? ?? 1,
      isBookmarked: (map['isBookmarked'] as int? ?? 0) == 1,
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
