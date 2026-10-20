import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/preference_service.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/timetable_model.dart';
import '../../data/repositories/timer_repository.dart';
import '../auth/auth_controller.dart';
import '../exams/exams_controller.dart';
import '../tasks/tasks_controller.dart';
import '../timetable/timetable_controller.dart';

class HomeDashboardData {
  final String greeting;
  final String userName;
  final int todayTasksTotal;
  final int todayTasksCompleted;
  final double taskCompletionPercentage;
  final int todayStudyMinutes;
  final int dailyGoalMinutes;
  final double goalProgress;
  final int studyStreakDays;
  final Map<int, int> weeklyStudyMinutes;
  final List<ExamModel> upcomingExams;
  final List<TimetableModel> todayClasses;
  final List<TaskModel> todayTaskList;
  final TimetableModel? nextClass;
  final String motivationalQuote;

  const HomeDashboardData({
    required this.greeting,
    required this.userName,
    required this.todayTasksTotal,
    required this.todayTasksCompleted,
    required this.taskCompletionPercentage,
    required this.todayStudyMinutes,
    required this.dailyGoalMinutes,
    required this.goalProgress,
    required this.studyStreakDays,
    required this.weeklyStudyMinutes,
    required this.upcomingExams,
    required this.todayClasses,
    this.todayTaskList = const [],
    this.nextClass,
    required this.motivationalQuote,
  });
}

final homeDashboardProvider = FutureProvider<HomeDashboardData>((ref) async {
  final user = ref.watch(currentProfileProvider);
  final userId = user?.uid ?? 'guest';
  final userName = user?.displayName.isNotEmpty == true
      ? user!.displayName
      : 'Scholar';

  final timerRepo = ref.watch(timerRepositoryProvider);
  final prefs = ref.watch(preferenceServiceProvider);

  // Time & Greeting
  final now = DateTime.now();
  String greeting = 'Good evening';
  if (now.hour < 12) {
    greeting = 'Good morning';
  } else if (now.hour < 17) {
    greeting = 'Good afternoon';
  }

  // Tasks statistics & today's tasks list
  final tasksState = ref.watch(tasksControllerProvider);
  int todayTotal = 0;
  int todayCompleted = 0;
  List<TaskModel> todayTaskList = [];

  tasksState.whenData((tasks) {
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final todayTasks = tasks
        .where(
          (t) => (t.dueDate.isAfter(todayStart) && t.dueDate.isBefore(todayEnd)) || (t.isOverdue && !t.isCompleted),
        )
        .toList();
    todayTaskList = todayTasks;
    todayTotal = todayTasks.length;
    todayCompleted = todayTasks.where((t) => t.isCompleted).length;
  });

  final taskPercentage = todayTotal > 0 ? (todayCompleted / todayTotal) : 0.0;

  // Study time & streak
  final todayStudyMinutes = await timerRepo.getTodayStudyMinutes(userId);
  final weeklyStudyMinutes = await timerRepo.getWeeklyStudyMinutes(userId);
  final allSessions = await timerRepo.getSessions(userId);
  final streak = timerRepo.calculateStudyStreak(allSessions);

  final dailyGoal = prefs.getDailyGoalMinutes();
  final goalProgress = dailyGoal > 0
      ? (todayStudyMinutes / dailyGoal).clamp(0.0, 1.0)
      : 0.0;

  // Upcoming Exams
  final upcomingExams = ref.watch(upcomingExamsProvider);

  // Today Timetable & Next Class
  final todayClasses = ref.watch(currentDayClassesProvider);
  final currentMinutes = now.hour * 60 + now.minute;
  TimetableModel? nextClass;
  for (final c in todayClasses) {
    if (c.startMinutes > currentMinutes) {
      nextClass = c;
      break;
    }
  }

  // Dynamic motivational quotes
  final quotes = [
    'Success is the sum of small efforts repeated day in and day out.',
    'Focus on being productive instead of busy.',
    'Discipline is choosing between what you want now and what you want most.',
    'Small steps every day lead to massive results over time.',
    'Deep focus is your superpower in a world full of distractions.',
  ];
  final quote = quotes[now.day % quotes.length];

  return HomeDashboardData(
    greeting: greeting,
    userName: userName,
    todayTasksTotal: todayTotal,
    todayTasksCompleted: todayCompleted,
    taskCompletionPercentage: taskPercentage,
    todayStudyMinutes: todayStudyMinutes,
    dailyGoalMinutes: dailyGoal,
    goalProgress: goalProgress,
    studyStreakDays: streak,
    weeklyStudyMinutes: weeklyStudyMinutes,
    upcomingExams: upcomingExams,
    todayClasses: todayClasses,
    todayTaskList: todayTaskList,
    nextClass: nextClass,
    motivationalQuote: quote,
  );
});
