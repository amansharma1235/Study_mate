import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_card.dart';
import 'quiz_controller.dart';

class AnswerReviewScreen extends ConsumerWidget {
  const AnswerReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = ref.watch(quizSessionControllerProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Answer Review')),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.space16),
        itemCount: session.questions.length,
        itemBuilder: (context, idx) {
          final q = session.questions[idx];
          final selected = session.selectedAnswers[idx];
          final isCorrect = selected == q.correctIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? AppColors.successLight
                              : AppColors.errorLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isCorrect ? 'Correct ✓' : 'Incorrect ✗',
                          style: TextStyle(
                            color: isCorrect
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Question ${idx + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    q.question,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Display all 4 options
                  ...List.generate(q.options.length, (optIdx) {
                    final isUserChoice = selected == optIdx;
                    final isActualCorrect = q.correctIndex == optIdx;

                    Color? optBg;
                    Color? optFg;

                    if (isActualCorrect) {
                      optBg = AppColors.successLight;
                      optFg = AppColors.success;
                    } else if (isUserChoice && !isCorrect) {
                      optBg = AppColors.errorLight;
                      optFg = AppColors.error;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            optBg ??
                            (isDark
                                ? AppColors.surfaceDark
                                : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              optFg ??
                              (isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${String.fromCharCode(65 + optIdx)}. ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color:
                                  optFg ??
                                  (isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              q.options[optIdx],
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    optFg ??
                                    (isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight),
                              ),
                            ),
                          ),
                          if (isActualCorrect)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 18,
                            )
                          else if (isUserChoice && !isCorrect)
                            const Icon(
                              Icons.cancel_rounded,
                              color: AppColors.error,
                              size: 18,
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),

                  // Explanation Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.primaryLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMedium,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Explanation:',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          q.explanation,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
