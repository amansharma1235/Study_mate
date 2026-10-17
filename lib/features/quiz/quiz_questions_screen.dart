import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialogs.dart';
import 'quiz_controller.dart';

class QuizQuestionsScreen extends ConsumerWidget {
  const QuizQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = ref.watch(quizSessionControllerProvider);
    final controller = ref.read(quizSessionControllerProvider.notifier);

    if (session.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(
          child: Text('No questions available in this category.'),
        ),
      );
    }

    final currentQ = session.currentQuestion!;
    final selectedOption = session.selectedAnswers[session.currentIndex];
    final progress = (session.currentIndex + 1) / session.questions.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await AppDialogs.showConfirmDialog(
          context: context,
          title: 'Exit Quiz?',
          message: 'Your current quiz progress will be lost if you leave now.',
          confirmText: 'Exit',
          isDestructive: true,
        );
        if (leave == true && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(session.category.isEmpty ? 'Quiz' : session.category),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${session.currentIndex + 1}/${session.questions.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark
                    ? AppColors.surfaceDark
                    : AppColors.primaryLight,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 4,
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.space20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSmall,
                          ),
                        ),
                        child: Text(
                          currentQ.category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Question Text
                      Text(
                        currentQ.question,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space24),

                      // Answer Options List
                      ...List.generate(currentQ.options.length, (optIdx) {
                        final optionText = currentQ.options[optIdx];
                        final isSelected = selectedOption == optIdx;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            onTap: () => controller.selectOption(optIdx),
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : (isDark ? AppColors.cardDark : Colors.white),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight),
                              width: isSelected ? 2 : 1,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark
                                                ? AppColors.borderDark
                                                : AppColors.borderLight),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(
                                        65 + optIdx,
                                      ), // A, B, C, D
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                  ? AppColors.textSecondaryDark
                                                  : AppColors.textPrimaryLight),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.space12),
                                Expanded(
                                  child: Text(
                                    optionText,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Bottom Navigation Controls
              Container(
                padding: const EdgeInsets.all(AppDimensions.space16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (session.currentIndex > 0)
                      Expanded(
                        child: AppButton(
                          text: 'Previous',
                          variant: AppButtonVariant.outline,
                          onPressed: () => controller.previousQuestion(),
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: AppDimensions.space16),
                    Expanded(
                      child: AppButton(
                        text: session.isLastQuestion ? 'Submit Quiz' : 'Next',
                        variant: AppButtonVariant.primary,
                        onPressed: () async {
                          if (session.isLastQuestion) {
                            await controller.submitQuiz();
                            if (context.mounted) {
                              context.pushReplacement(AppRoutes.quizResults);
                            }
                          } else {
                            controller.nextQuestion();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
