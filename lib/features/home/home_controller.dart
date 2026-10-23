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

class StudyQuote {
  final String quote;
  final String author;
  final String shortHandwritten;

  const StudyQuote({
    required this.quote,
    required this.author,
    required this.shortHandwritten,
  });
}

const kDynamicStudyQuotes = [
  StudyQuote(
    quote: 'Success is the sum of small efforts repeated day in and day out.',
    author: 'Robert Collier',
    shortHandwritten: '“ Small\nsteps every day\nlead to big\nresults. ”',
  ),
  StudyQuote(
    quote: 'The expert in anything was once a beginner. Keep learning and growing!',
    author: 'Helen Hayes',
    shortHandwritten: '“ Learn with\npassion &\npersist every\nsingle day. ”',
  ),
  StudyQuote(
    quote: 'Deep focus is your superpower in a world full of digital distractions.',
    author: 'Cal Newport',
    shortHandwritten: '“ Protect your\nfocus, master\nyour craft. ”',
  ),
  StudyQuote(
    quote: 'Discipline is choosing between what you want now and what you want most.',
    author: 'Abraham Lincoln',
    shortHandwritten: '“ Discipline\ncreates true\nfreedom. ”',
  ),
  StudyQuote(
    quote: 'Your future is created by what you do today, not tomorrow.',
    author: 'Peter Drucker',
    shortHandwritten: '“ Make today\ncount towards\nyour dream. ”',
  ),
  StudyQuote(
    quote: 'Small daily improvements over time lead to stunning, lasting results.',
    author: 'Robin Sharma',
    shortHandwritten: '“ 1% better\nevery day\ncompounds. ”',
  ),
  StudyQuote(
    quote: 'Believe you can and you are halfway there. Keep moving forward!',
    author: 'Theodore Roosevelt',
    shortHandwritten: '“ Believe in\nyour power to\nsucceed. ”',
  ),
  StudyQuote(
    quote: 'It always seems impossible until it is done. Take the first step.',
    author: 'Nelson Mandela',
    shortHandwritten: '“ Done is better\nthan waiting\nfor perfect. ”',
  ),
  StudyQuote(
    quote: 'Strive for continuous progress, not impossible perfection.',
    author: 'Bill Phillips',
    shortHandwritten: '“ Progress over\nperfection\nalways. ”',
  ),
  StudyQuote(
    quote: 'Action is the foundational key to all great achievements.',
    author: 'Pablo Picasso',
    shortHandwritten: '“ Take action\nnow, results\nwill follow. ”',
  ),
];

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
  final StudyQuote studyQuote;
  final List<StudyQuote> allQuotes;

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
    required this.studyQuote,
    this.allQuotes = kDynamicStudyQuotes,
  });
}

final homeDashboardProvider = FutureProvider<HomeDashboardData>((ref) async {
  final user = ref.watch(currentProfileProvider);
  final userId = user?.uid ?? 'guest';
  final userName = user?.displayName.isNotEmpty == true
      ? user!.displayName
      : (user?.email.isNotEmpty == true ? user!.email.split('@').first : 'Scholar');

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
  int todayStudyMinutes = 0;
  Map<int, int> weeklyStudyMinutes = const {};
  int streak = 0;
  try {
    todayStudyMinutes = await timerRepo.getTodayStudyMinutes(userId);
    weeklyStudyMinutes = await timerRepo.getWeeklyStudyMinutes(userId);
    final allSessions = await timerRepo.getSessions(userId);
    streak = timerRepo.calculateStudyStreak(allSessions);
  } catch (e) {
    // Graceful offline fallback
  }

  final dailyGoal = (user?.dailyGoalMinutes != null && user!.dailyGoalMinutes > 0)
      ? user.dailyGoalMinutes
      : prefs.getDailyGoalMinutes(userId);
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

  // Dynamic academic motivational quote based on day of year
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
  final studyQuote = kDynamicStudyQuotes[dayOfYear % kDynamicStudyQuotes.length];

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
    motivationalQuote: studyQuote.quote,
    studyQuote: studyQuote,
    allQuotes: kDynamicStudyQuotes,
  );
});
