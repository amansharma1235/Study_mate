import 'sync_status.dart';

class HabitModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String iconName;
  final String colorHex;
  final int targetDaysPerWeek;
  final int currentStreak;
  final int bestStreak;
  final List<String> completedDates; // List of "YYYY-MM-DD"
  final String reminderTime; // "08:00"
  final DateTime createdAt;
  final SyncStatus syncStatus;

  HabitModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.iconName = 'check_circle',
    this.colorHex = '#10B981',
    this.targetDaysPerWeek = 7,
    this.currentStreak = 0,
    this.bestStreak = 0,
    List<String>? completedDates,
    this.reminderTime = '08:00',
    DateTime? createdAt,
    this.syncStatus = SyncStatus.synced,
  }) : completedDates = completedDates ?? [],
       createdAt = createdAt ?? DateTime.now();

  bool isCompletedToday() {
    final todayStr = _formatDate(DateTime.now());
    return completedDates.contains(todayStr);
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'iconName': iconName,
      'colorHex': colorHex,
      'targetDaysPerWeek': targetDaysPerWeek,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'completedDates': completedDates.join(','),
      'reminderTime': reminderTime,
      'createdAt': createdAt.toIso8601String(),
      'syncStatus': syncStatus.name,
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    final datesStr = map['completedDates'] as String? ?? '';
    final dates = datesStr.isNotEmpty ? datesStr.split(',') : <String>[];

    return HabitModel(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      iconName: map['iconName'] as String? ?? 'check_circle',
      colorHex: map['colorHex'] as String? ?? '#10B981',
      targetDaysPerWeek: map['targetDaysPerWeek'] as int? ?? 7,
      currentStreak: map['currentStreak'] as int? ?? 0,
      bestStreak: map['bestStreak'] as int? ?? 0,
      completedDates: dates,
      reminderTime: map['reminderTime'] as String? ?? '08:00',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == map['syncStatus'],
        orElse: () => SyncStatus.synced,
      ),
    );
  }

  HabitModel toggleToday() {
    final todayStr = _formatDate(DateTime.now());
    final newDates = List<String>.from(completedDates);
    int newCurrentStreak = currentStreak;
    int newBestStreak = bestStreak;

    if (newDates.contains(todayStr)) {
      newDates.remove(todayStr);
      newCurrentStreak = (newCurrentStreak > 0) ? newCurrentStreak - 1 : 0;
    } else {
      newDates.add(todayStr);
      newCurrentStreak += 1;
      if (newCurrentStreak > newBestStreak) {
        newBestStreak = newCurrentStreak;
      }
    }

    return HabitModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      iconName: iconName,
      colorHex: colorHex,
      targetDaysPerWeek: targetDaysPerWeek,
      currentStreak: newCurrentStreak,
      bestStreak: newBestStreak,
      completedDates: newDates,
      reminderTime: reminderTime,
      createdAt: createdAt,
      syncStatus: SyncStatus.pending,
    );
  }
}
