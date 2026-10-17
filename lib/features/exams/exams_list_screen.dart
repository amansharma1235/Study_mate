import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/exam_model.dart';
import 'exams_controller.dart';

class ExamsListScreen extends ConsumerWidget {
  const ExamsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final examsState = ref.watch(examsControllerProvider);

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
              description: 'Stay ahead of your academic calendar by adding exams, midterms, and finals.',
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
