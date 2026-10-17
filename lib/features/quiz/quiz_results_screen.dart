import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import 'quiz_controller.dart';

class QuizResultsScreen extends ConsumerWidget {
  const QuizResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = ref.watch(quizSessionControllerProvider);

    final isPassed = session.scorePercentage >= 60.0;
    final incorrectCount = session.questions.length - session.correctCount;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Quiz Results'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            children: [
              // Circular Result Card
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isPassed
                      ? AppColors.successLight
                      : AppColors.warningLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPassed
                      ? Icons.emoji_events_rounded
                      : Icons.lightbulb_outline_rounded,
                  size: 52,
                  color: isPassed ? AppColors.success : AppColors.warning,
                ),
              ),
              const SizedBox(height: AppDimensions.space20),
              Text(
                isPassed ? 'Congratulations! 🎉' : 'Keep Practicing! 📚',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You scored ${session.scorePercentage.toInt()}% on ${session.category}',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppDimensions.space24),

              // Metrics Card
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(
                      'Total',
                      '${session.questions.length}',
                      AppColors.primary,
                      isDark,
                    ),
                    _buildStat(
                      'Correct',
                      '${session.correctCount}',
                      AppColors.success,
                      isDark,
                    ),
                    _buildStat(
                      'Incorrect',
                      '$incorrectCount',
                      AppColors.error,
                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space32),

              AppButton(
                text: 'Review Answers & Explanations',
                variant: AppButtonVariant.primary,
                icon: Icons.assignment_turned_in_outlined,
                onPressed: () => context.push(AppRoutes.quizReview),
              ),
              const SizedBox(height: AppDimensions.space12),

              AppButton(
                text: 'Retake Quiz',
                variant: AppButtonVariant.outline,
                icon: Icons.replay_rounded,
                onPressed: () async {
                  await ref
                      .read(quizSessionControllerProvider.notifier)
                      .startQuiz(session.category);
                  if (context.mounted) {
                    context.pushReplacement(AppRoutes.quizQuestions);
                  }
                },
              ),
              const SizedBox(height: AppDimensions.space12),

              AppButton(
                text: 'Back to Quiz Topics',
                variant: AppButtonVariant.text,
                onPressed: () => context.go(AppRoutes.quizCategories),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
