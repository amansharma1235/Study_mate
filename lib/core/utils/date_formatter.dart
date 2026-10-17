import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('MMM d, yyyy • h:mm a');
  static final DateFormat _weekdayFormat = DateFormat('EEEE');
  static final DateFormat _shortWeekdayFormat = DateFormat('EEE');
  static final DateFormat _monthDayFormat = DateFormat('MMM d');

  static String formatDate(DateTime dt) => _dateFormat.format(dt);
  static String formatTime(DateTime dt) => _timeFormat.format(dt);
  static String formatDateTime(DateTime dt) => _dateTimeFormat.format(dt);
  static String formatWeekday(DateTime dt) => _weekdayFormat.format(dt);
  static String formatShortWeekday(DateTime dt) =>
      _shortWeekdayFormat.format(dt);
  static String formatMonthDay(DateTime dt) => _monthDayFormat.format(dt);

  static String formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String formatMinutesToHours(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  static String formatRemainingDays(DateTime targetDate) {
    final now = DateTime.now();
    final difference = targetDate.difference(now);
    if (difference.isNegative) {
      final daysAgo = difference.inDays.abs();
      return daysAgo == 0 ? 'Concluded today' : '$daysAgo days ago';
    }
    if (difference.inDays == 0) {
      if (difference.inHours > 0) return '${difference.inHours}h remaining';
      return '${difference.inMinutes}m remaining';
    }
    return '${difference.inDays} days left';
  }
}
