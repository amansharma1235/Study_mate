import 'sync_status.dart';

class VoiceNoteModel {
  final String id;
  final String userId;
  final String title;
  final String subject;
  final String audioPath;
  final int durationSeconds;
  final String transcription;
  final DateTime createdAt;
  final SyncStatus syncStatus;

  VoiceNoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.subject,
    required this.audioPath,
    this.durationSeconds = 0,
    this.transcription = '',
    DateTime? createdAt,
    this.syncStatus = SyncStatus.synced,
  }) : createdAt = createdAt ?? DateTime.now();

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'subject': subject,
      'audioPath': audioPath,
      'durationSeconds': durationSeconds,
      'transcription': transcription,
      'createdAt': createdAt.toIso8601String(),
      'syncStatus': syncStatus.name,
    };
  }

  factory VoiceNoteModel.fromMap(Map<String, dynamic> map) {
    return VoiceNoteModel(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subject: map['subject'] as String? ?? 'General',
      audioPath: map['audioPath'] as String? ?? '',
      durationSeconds: map['durationSeconds'] as int? ?? 0,
      transcription: map['transcription'] as String? ?? '',
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
