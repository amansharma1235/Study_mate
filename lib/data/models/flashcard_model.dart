import 'sync_status.dart';

enum CardRating { again, hard, good, easy }

class FlashcardDeckModel {
  final String id;
  final String userId;
  final String title;
  final String subject;
  final String description;
  final String colorHex;
  final int cardCount;
  final DateTime createdAt;
  final SyncStatus syncStatus;

  FlashcardDeckModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.subject,
    this.description = '',
    this.colorHex = '#6258E8',
    this.cardCount = 0,
    DateTime? createdAt,
    this.syncStatus = SyncStatus.synced,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'subject': subject,
      'description': description,
      'colorHex': colorHex,
      'cardCount': cardCount,
      'createdAt': createdAt.toIso8601String(),
      'syncStatus': syncStatus.name,
    };
  }

  factory FlashcardDeckModel.fromMap(Map<String, dynamic> map) {
    return FlashcardDeckModel(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subject: map['subject'] as String? ?? 'General',
      description: map['description'] as String? ?? '',
      colorHex: map['colorHex'] as String? ?? '#6258E8',
      cardCount: map['cardCount'] as int? ?? 0,
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

class FlashcardModel {
  final String id;
  final String deckId;
  final String userId;
  final String front;
  final String back;
  final String hint;
  final int intervalDays;
  final double easeFactor; // Default 2.5
  final int repetitionNumber;
  final DateTime nextReviewDate;
  final DateTime? lastReviewedAt;
  final SyncStatus syncStatus;

  FlashcardModel({
    required this.id,
    required this.deckId,
    required this.userId,
    required this.front,
    required this.back,
    this.hint = '',
    this.intervalDays = 0,
    this.easeFactor = 2.5,
    this.repetitionNumber = 0,
    DateTime? nextReviewDate,
    this.lastReviewedAt,
    this.syncStatus = SyncStatus.synced,
  }) : nextReviewDate = nextReviewDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deckId': deckId,
      'userId': userId,
      'front': front,
      'back': back,
      'hint': hint,
      'intervalDays': intervalDays,
      'easeFactor': easeFactor,
      'repetitionNumber': repetitionNumber,
      'nextReviewDate': nextReviewDate.toIso8601String(),
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'syncStatus': syncStatus.name,
    };
  }

  factory FlashcardModel.fromMap(Map<String, dynamic> map) {
    return FlashcardModel(
      id: map['id'] as String,
      deckId: map['deckId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      front: map['front'] as String? ?? '',
      back: map['back'] as String? ?? '',
      hint: map['hint'] as String? ?? '',
      intervalDays: map['intervalDays'] as int? ?? 0,
      easeFactor: (map['easeFactor'] as num?)?.toDouble() ?? 2.5,
      repetitionNumber: map['repetitionNumber'] as int? ?? 0,
      nextReviewDate:
          DateTime.tryParse(map['nextReviewDate'] as String? ?? '') ??
          DateTime.now(),
      lastReviewedAt: map['lastReviewedAt'] != null
          ? DateTime.tryParse(map['lastReviewedAt'] as String)
          : null,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == map['syncStatus'],
        orElse: () => SyncStatus.synced,
      ),
    );
  }

  // SM-2 Spaced Repetition Algorithm
  FlashcardModel review(CardRating rating) {
    int newRep = repetitionNumber;
    int newInterval = intervalDays;
    double newEase = easeFactor;

    switch (rating) {
      case CardRating.again:
        newRep = 0;
        newInterval = 1;
        newEase = (newEase - 0.2).clamp(1.3, 3.0);
        break;
      case CardRating.hard:
        newRep = (newRep > 0) ? newRep + 1 : 1;
        newInterval = (newInterval * 1.2).round().clamp(1, 365);
        newEase = (newEase - 0.15).clamp(1.3, 3.0);
        break;
      case CardRating.good:
        newRep = newRep + 1;
        if (newRep == 1) {
          newInterval = 1;
        } else if (newRep == 2) {
          newInterval = 6;
        } else {
          newInterval = (newInterval * newEase).round();
        }
        break;
      case CardRating.easy:
        newRep = newRep + 1;
        if (newRep == 1) {
          newInterval = 4;
        } else if (newRep == 2) {
          newInterval = 10;
        } else {
          newInterval = (newInterval * newEase * 1.3).round();
        }
        newEase = (newEase + 0.15).clamp(1.3, 3.0);
        break;
    }

    final nextDate = DateTime.now().add(Duration(days: newInterval));

    return FlashcardModel(
      id: id,
      deckId: deckId,
      userId: userId,
      front: front,
      back: back,
      hint: hint,
      intervalDays: newInterval,
      easeFactor: newEase,
      repetitionNumber: newRep,
      nextReviewDate: nextDate,
      lastReviewedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );
  }
}
