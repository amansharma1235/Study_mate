import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/speed_dial_fab.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/task_model.dart';
import '../../data/remote/sync_service.dart';
import '../auth/auth_controller.dart';
import '../tasks/tasks_controller.dart';
import 'home_controller.dart';

/// Clean, minimal, and student-focused Home Screen UI.
/// Adheres strictly to the requested 5 essential sections and color palette.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // UI Theme Constants as specified
  static const Color _primaryColor = Color(0xFF6258E8);
  static const Color _secondaryColor = Color(0xFF3987F5);
  static const Color _lightBg = Color(0xFFF7F7FC);
  static const Color _darkBg = Color(0xFF111327);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentProfileProvider);
    final dashboardAsync = ref.watch(homeDashboardProvider);
    final syncState = ref.watch(syncStateProvider);

    final bgColor = isDark ? _darkBg : _lightBg;
    final cardBg = isDark ? const Color(0xFF191B33) : Colors.white;
    final borderColor = isDark ? const Color(0xFF26294D) : const Color(0xFFEAEAEE);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1C29);
    final textMuted = isDark ? const Color(0xFF8E95AA) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(context, ref, user, syncState, isDark, textPrimary, textMuted),
      body: dashboardAsync.when(
        loading: () => _buildLoadingState(isDark),
        error: (err, _) => _buildErrorState(ref, err),
        data: (data) => RefreshIndicator(
          color: _primaryColor,
          onRefresh: () async {
            ref.invalidate(homeDashboardProvider);
            ref.read(tasksControllerProvider.notifier).loadTasks();
            if (user != null && user.uid.isNotEmpty) {
              await ref.read(syncStateProvider.notifier).triggerSync(user.uid);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: AppDimensions.space12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Compact Header & Motivation
                _buildHeader(data, textPrimary, textMuted, isDark),
                const SizedBox(height: 16),

                // 2. Today's Study Goal
                _buildStudyGoalCard(data, cardBg, borderColor, textPrimary, textMuted),
                const SizedBox(height: 16),

                // 3. Four Quick Actions
                _buildQuickActions(context, cardBg, borderColor, textPrimary, isDark),
                const SizedBox(height: 20),

                // 4. Today's Tasks
                _buildTodayTasks(context, ref, data, cardBg, borderColor, textPrimary, textMuted, isDark),
                const SizedBox(height: 16),

                // 5. Upcoming Exam
                _buildUpcomingExam(context, data, cardBg, borderColor, textPrimary, textMuted, isDark),
                const SizedBox(height: 80), // Room for Floating Action Button
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: const SpeedDialFab(),
    );
  }

  /// AppBar: StudyMate Branding + Sync Status + Profile Avatar
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    SyncState syncState,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    return AppBar(
      backgroundColor: isDark ? _darkBg : _lightBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: AppDimensions.space16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/branding/studymate_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              children: [
                TextSpan(
                  text: 'Study',
                  style: TextStyle(color: textPrimary),
                ),
                const TextSpan(
                  text: 'Mate',
                  style: TextStyle(color: _secondaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: syncState.isSyncing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primaryColor,
                  ),
                )
              : Icon(
                  syncState.isCloudConnected
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  color: syncState.isCloudConnected
                      ? const Color(0xFF10B981)
                      : textMuted,
                  size: 20,
                ),
          tooltip: syncState.isCloudConnected ? 'Cloud Synced' : 'Offline Mode',
          onPressed: () {
            if (user != null && user.uid.isNotEmpty) {
              ref.read(syncStateProvider.notifier).triggerSync(user.uid);
            }
          },
        ),
        InkWell(
          onTap: () => context.push(AppRoutes.profile),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: UserAvatar(
              photoUrl: user?.photoUrl,
              name: user?.displayName ?? 'Student',
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  /// 1. Compact Header: Greeting, date & Daily Motivation
  Widget _buildHeader(
    HomeDashboardData data,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.greeting}, ${data.userName} 👋',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.formatDate(DateTime.now()),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (data.studyStreakDays > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFD97706),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${data.studyStreakDays}d streak',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (data.motivationalQuote.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: isDark ? 0.12 : 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: _primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAILY MOTIVATION',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '“${data.motivationalQuote}”',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 2. Today's Study Goal Card
  Widget _buildStudyGoalCard(
    HomeDashboardData data,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textMuted,
  ) {
    final progressPercent = (data.goalProgress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Study Goal",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              Text(
                '$progressPercent%',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: data.goalProgress,
              backgroundColor: _primaryColor.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(_primaryColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${data.todayStudyMinutes}m completed',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                'Target: ${data.dailyGoalMinutes}m',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. Four Quick Actions: Start Studying, My Tasks, My Notes, Timetable
  Widget _buildQuickActions(
    BuildContext context,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildActionItem(
            icon: Icons.play_arrow_rounded,
            label: 'Start\nStudying',
            iconColor: _primaryColor,
            bgColor: _primaryColor.withValues(alpha: 0.1),
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textPrimary,
            onTap: () => context.push(AppRoutes.timer),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionItem(
            icon: Icons.check_circle_outline_rounded,
            label: 'My\nTasks',
            iconColor: _secondaryColor,
            bgColor: _secondaryColor.withValues(alpha: 0.1),
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textPrimary,
            onTap: () => context.go(AppRoutes.tasks),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionItem(
            icon: Icons.edit_note_rounded,
            label: 'My\nNotes',
            iconColor: const Color(0xFF10B981),
            bgColor: const Color(0xFF10B981).withValues(alpha: 0.1),
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textPrimary,
            onTap: () => context.go(AppRoutes.notes),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionItem(
            icon: Icons.calendar_today_rounded,
            label: 'Time\ntable',
            iconColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textPrimary,
            onTap: () => context.push(AppRoutes.timetable),
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 4. Today's Tasks (3 most relevant incomplete tasks with View All)
  Widget _buildTodayTasks(
    BuildContext context,
    WidgetRef ref,
    HomeDashboardData data,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    // Filter only incomplete tasks for today (or overdue incomplete)
    final pendingTasks = data.todayTaskList.where((t) => !t.isCompleted).take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Tasks",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.tasks),
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pendingTasks.isEmpty)
            _buildTasksEmptyState(context, textMuted, isDark)
          else
            ...pendingTasks.map((task) => _buildTaskRow(context, ref, task, textPrimary, textMuted, isDark)),
        ],
      ),
    );
  }

  Widget _buildTasksEmptyState(BuildContext context, Color textMuted, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF10B981),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No pending tasks for today',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.createTask),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '+ Add Task',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.push(AppRoutes.editTask, extra: task),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            GestureDetector(
              onTap: () async {
                await ref.read(tasksControllerProvider.notifier).toggleTask(task);
                ref.invalidate(homeDashboardProvider);
              },
              child: Icon(
                task.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: task.isCompleted
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.white38 : Colors.black26),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.formatDate(task.dueDate),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _buildPriorityBadge(task.priority),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    Color bg;
    Color text;
    String label;

    switch (priority) {
      case TaskPriority.high:
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFDC2626);
        label = 'High';
        break;
      case TaskPriority.medium:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFD97706);
        label = 'Med';
        break;
      case TaskPriority.low:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF64748B);
        label = 'Low';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }

  /// 5. Upcoming Exam: Nearest upcoming exam, or compact Add Exam prompt
  Widget _buildUpcomingExam(
    BuildContext context,
    HomeDashboardData data,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    // Find nearest future exam
    final upcoming = data.upcomingExams.where((e) => !e.isCompleted && !e.isPast).toList()
      ..sort((a, b) => a.examDate.compareTo(b.examDate));

    final ExamModel? nearest = upcoming.isNotEmpty ? upcoming.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Exam',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.exams),
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _secondaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (nearest != null)
            _buildNearestExamRow(context, nearest, textPrimary, textMuted, isDark)
          else
            _buildNoExamState(context, textMuted),
        ],
      ),
    );
  }

  Widget _buildNearestExamRow(
    BuildContext context,
    ExamModel exam,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    final now = DateTime.now();
    final difference = exam.examDate.difference(DateTime(now.year, now.month, now.day)).inDays;
    String countdown;
    if (difference == 0) {
      countdown = 'Today';
    } else if (difference == 1) {
      countdown = 'Tomorrow';
    } else {
      countdown = 'In $difference days';
    }

    return InkWell(
      onTap: () => context.push(AppRoutes.exams),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _secondaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: _secondaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${exam.title.isNotEmpty ? '${exam.title} • ' : ''}${DateFormatter.formatDate(exam.examDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _secondaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              countdown,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _secondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoExamState(BuildContext context, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.event_available_rounded, color: textMuted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No upcoming exams',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.addExam),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '+ Add Exam',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _secondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.space16),
      child: Column(
        children: [
          LoadingSkeleton(width: double.infinity, height: 48),
          SizedBox(height: 16),
          LoadingSkeleton(width: double.infinity, height: 96),
          SizedBox(height: 16),
          LoadingSkeleton(width: double.infinity, height: 80),
          SizedBox(height: 16),
          LoadingSkeleton(width: double.infinity, height: 130),
          SizedBox(height: 16),
          LoadingSkeleton(width: double.infinity, height: 75),
        ],
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 44, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              'Could not load dashboard: $err',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(homeDashboardProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
