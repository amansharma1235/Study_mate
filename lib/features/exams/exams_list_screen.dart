import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/exam_model.dart';
import '../flashcards/flashcards_controller.dart';
import '../home/home_controller.dart';
import 'exams_controller.dart';
import 'widgets/exam_roadmap_dialog.dart';

class ExamsListScreen extends ConsumerWidget {
  const ExamsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final examsState = ref.watch(examsControllerProvider);
    final dashboardAsync = ref.watch(homeDashboardProvider);
    final flashcardsAsync = ref.watch(flashcardDecksProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Exam Countdowns',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Exam',
            onPressed: () => context.push(AppRoutes.addExam),
          ),
        ],
      ),
      body: examsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading exams: $err')),
        data: (exams) {
          if (exams.isEmpty) {
            return EmptyState(
              icon: Icons.alarm_rounded,
              title: 'No Exams Added',
              description:
                  'Stay ahead of your academic calendar by adding exams, midterms, and finals.',
              buttonText: 'Add Exam',
              onButtonPressed: () => context.push(AppRoutes.addExam),
            );
          }

          final upcoming =
              exams.where((e) => !e.isCompleted && !e.isPast).toList()
                ..sort((a, b) => a.examDate.compareTo(b.examDate));
          final completedOrPast =
              exams.where((e) => e.isCompleted || e.isPast).toList()
                ..sort((a, b) => b.examDate.compareTo(a.examDate));

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.space16),
            children: [
              // AI Exam Simulator Launch Card
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E1B4B), const Color(0xFF311042)]
                        : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.timer_outlined, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Exam Simulator & Mock Test',
                            style: GoogleFonts.outfit(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Practice with real timer & negative marking',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => context.push(AppRoutes.examSimulatorConfig),
                      child: Text(
                        'Launch 🎯',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Predictive Exam Readiness Score Card
              if (upcoming.isNotEmpty) ...[
                _buildReadinessScoreCard(
                  context: context,
                  isDark: isDark,
                  nearestExam: upcoming.first,
                  dashboardAsync: dashboardAsync,
                  flashcardsAsync: flashcardsAsync,
                ),
                const SizedBox(height: 20),
              ],

              if (upcoming.isNotEmpty) ...[
                Text(
                  'Upcoming Exams (${upcoming.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 10),
                ...upcoming.map(
                  (exam) =>
                      _buildExamCard(context, ref, exam, isDark, isPast: false),
                ),
                const SizedBox(height: 20),
              ],
              if (completedOrPast.isNotEmpty) ...[
                Text(
                  'Past & Completed (${completedOrPast.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 10),
                ...completedOrPast.map(
                  (exam) =>
                      _buildExamCard(context, ref, exam, isDark, isPast: true),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 28),
        onPressed: () => context.push(AppRoutes.addExam),
      ),
    );
  }

  Widget _buildReadinessScoreCard({
    required BuildContext context,
    required bool isDark,
    required ExamModel nearestExam,
    required AsyncValue<HomeDashboardData> dashboardAsync,
    required AsyncValue<List<dynamic>> flashcardsAsync,
  }) {
    final now = DateTime.now();
    final daysUntil = math.max(0, nearestExam.examDate.difference(now).inDays);

    // Calculate metrics safely from providers
    int streakDays = 0;
    int weeklyStudyMins = 0;
    double taskCompletion = 0.0;

    dashboardAsync.whenData((data) {
      streakDays = data.studyStreakDays;
      weeklyStudyMins = data.weeklyStudyMinutes.values.fold(0, (a, b) => a + b);
      taskCompletion = data.taskCompletionPercentage;
    });

    int totalCards = 0;
    flashcardsAsync.whenData((decks) {
      for (final d in decks) {
        totalCards += (d.cardsCount as int? ?? 0);
      }
    });

    // Predictive Exam Readiness Formula (0 - 100%)
    // 1. Consistency & Streak (max 30 pts)
    final streakScore = math.min(30.0, streakDays * 6.0);

    // 2. Weekly Focus Volume (target 300 mins ~ 5 hrs) (max 30 pts)
    final volumeScore = math.min(30.0, (weeklyStudyMins / 300.0) * 30.0);

    // 3. Active Recall & Task Prep (max 25 pts)
    final prepScore = (taskCompletion * 15.0) + math.min(10.0, totalCards * 1.5);

    // 4. Baseline Calendar Organization (15 pts)
    const baseScore = 15.0;

    final rawScore = (streakScore + volumeScore + prepScore + baseScore)
        .clamp(20.0, 98.0)
        .round();

    // Determine status badge & color
    final String statusLabel;
    final Color statusColor;
    final IconData statusIcon;

    if (rawScore >= 80) {
      statusLabel = 'Exam Ready';
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_rounded;
    } else if (rawScore >= 55) {
      statusLabel = 'On Track';
      statusColor = AppColors.primary;
      statusIcon = Icons.trending_up_rounded;
    } else {
      statusLabel = 'Needs Focus';
      statusColor = AppColors.warning;
      statusIcon = Icons.priority_high_rounded;
    }

    // Dynamic AI Revision Recommendation
    final String adviceText;
    if (daysUntil <= 2) {
      adviceText =
          'T-$daysUntil days! Avoid learning heavy new theory. Focus exclusively on rapid formula recall, high-yield summary sheets, and past examination papers for ${nearestExam.subject}.';
    } else if (daysUntil <= 7) {
      adviceText =
          '1 week milestone for ${nearestExam.subject}! Review your flashcard decks, test yourself without looking at solutions, and run 45-minute deep focus sprints.';
    } else {
      adviceText =
          '$daysUntil days remaining for ${nearestExam.subject}. Ideal preparation phase: create structured notes, generate AI flashcards, and establish a daily 25-minute Pomodoro rhythm.';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2235), const Color(0xFF141724)]
              : [const Color(0xFFEFF3FE), const Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFD6E2FC),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: AI Badge & Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'AI Predictive Readiness',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Main Metric Row: Circular Gauge + Subject Detail
          Row(
            children: [
              // Progress Ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      value: rawScore / 100.0,
                      strokeWidth: 7,
                      backgroundColor: isDark
                          ? const Color(0xFF2B3047)
                          : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$rawScore%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const Text(
                        'Score',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // Nearest Exam Focus Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nearest Target: ${nearestExam.subject}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${nearestExam.title} • in ${DateFormatter.formatRemainingDays(nearestExam.examDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: daysUntil <= 3
                            ? AppColors.error
                            : AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Quick stats pill row
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        _buildMetricChip(
                          icon: Icons.timer_outlined,
                          text: '${(weeklyStudyMins / 60).toStringAsFixed(1)}h/wk',
                          isDark: isDark,
                        ),
                        _buildMetricChip(
                          icon: Icons.local_fire_department_rounded,
                          text: '$streakDays d streak',
                          isDark: isDark,
                        ),
                        _buildMetricChip(
                          icon: Icons.style_outlined,
                          text: '$totalCards cards',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Actionable AI Advice Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF191B26)
                  : const Color(0xFFF6F8FE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    adviceText,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons: AI Revision Strategy & Start Focus Timer
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                  label: const Text(
                    'AI Revision Plan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    ExamRoadmapDialog.show(context, nearestExam);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text(
                    'Focus Session',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    context.push(AppRoutes.timer);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2E42) : const Color(0xFFE8EEFA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(
    BuildContext context,
    WidgetRef ref,
    ExamModel exam,
    bool isDark, {
    required bool isPast,
  }) {
    final remaining = DateFormatter.formatRemainingDays(exam.examDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => context.push(AppRoutes.editExam, extra: exam),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isPast
                    ? (isDark ? AppColors.surfaceDark : AppColors.borderLight)
                    : AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Column(
                children: [
                  Icon(
                    isPast
                        ? Icons.check_circle_outline_rounded
                        : Icons.timer_outlined,
                    color: isPast
                        ? AppColors.textSecondaryLight
                        : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remaining,
                    style: TextStyle(
                      color: isPast
                          ? AppColors.textSecondaryLight
                          : AppColors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      decoration: exam.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exam.subject} • ${DateFormatter.formatDate(exam.examDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  if (exam.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      exam.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.route_outlined, size: 20),
              color: AppColors.primary,
              tooltip: 'AI Revision Roadmap',
              onPressed: () => ExamRoadmapDialog.show(context, exam),
            ),
            Checkbox(
              value: exam.isCompleted,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (_) {
                ref
                    .read(examsControllerProvider.notifier)
                    .toggleCompleted(exam);
              },
            ),
          ],
        ),
      ),
    );
  }
}
