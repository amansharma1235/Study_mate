import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import 'exam_simulator_controller.dart';

class ExamSimulatorScreen extends ConsumerWidget {
  const ExamSimulatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(examSimulatorControllerProvider);
    final controller = ref.read(examSimulatorControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam Simulator')),
        body: const Center(
          child: Text('No active exam questions found.'),
        ),
      );
    }

    final currentQ = state.currentQuestion!;
    final minutes = state.remainingSeconds ~/ 60;
    final seconds = state.remainingSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final isTimeLow = state.remainingSeconds < 120; // less than 2 minutes

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await AppDialogs.showConfirmDialog(
          context: context,
          title: 'Abandon Exam Simulation?',
          message:
              'Leaving will discard your current mock test answers and time metrics.',
          confirmText: 'Abandon',
          isDestructive: true,
        );
        if (leave == true && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.config?.title ?? 'Exam Simulator',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Question ${state.currentIndex + 1} of ${state.questions.length}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          actions: [
            // Timer Badge
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isTimeLow
                    ? AppColors.error.withValues(alpha: 0.16)
                    : (isDark ? AppColors.cardDark : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isTimeLow ? AppColors.error : AppColors.primary,
                  width: isTimeLow ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: isTimeLow ? AppColors.error : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeStr,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isTimeLow ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Palette Grid Icon
            IconButton(
              icon: const Icon(Icons.grid_view_rounded),
              tooltip: 'Question Palette',
              onPressed: () => _showQuestionPalette(context, ref),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Linear Progress Bar
            LinearProgressIndicator(
              value: (state.currentIndex + 1) / state.questions.length,
              backgroundColor: isDark ? AppColors.cardDark : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Header Chips
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            currentQ.subtopic,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (currentQ.isMarkedForReview)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.flag_rounded,
                                    size: 13, color: Colors.purple),
                                const SizedBox(width: 4),
                                Text(
                                  'Marked for Review',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Question Text Card
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        currentQ.question,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Options List
                    Text(
                      'Choose Option:',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ...List.generate(currentQ.options.length, (optIdx) {
                      final isSelected = currentQ.selectedOptionIndex == optIdx;
                      final optionLetters = ['A', 'B', 'C', 'D'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            controller.selectOption(optIdx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : (isDark
                                      ? AppColors.cardDark
                                      : Colors.white),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.surfaceDark
                                            : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      optionLetters[optIdx],
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimaryLight),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    currentQ.options[optIdx],
                                    style: GoogleFonts.inter(
                                      fontSize: 14.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Dock
            _buildBottomDock(context, ref, state, controller, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomDock(
    BuildContext context,
    WidgetRef ref,
    ExamSimulatorState state,
    ExamSimulatorController controller,
    bool isDark,
  ) {
    final currentQ = state.currentQuestion!;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -3),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick Action Row (Clear, Flag, Palette)
            Row(
              children: [
                if (currentQ.isAttempted)
                  TextButton.icon(
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    label: const Text('Clear Selection'),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      controller.clearOption();
                    },
                  ),
                const Spacer(),
                OutlinedButton.icon(
                  icon: Icon(
                    currentQ.isMarkedForReview
                        ? Icons.flag_rounded
                        : Icons.outlined_flag_rounded,
                    size: 16,
                    color: Colors.purple,
                  ),
                  label: Text(
                    currentQ.isMarkedForReview ? 'Unmark Review' : 'Mark Review',
                    style: const TextStyle(color: Colors.purple),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    controller.toggleMarkForReview();
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Navigation Row (Previous, Next / Submit)
            Row(
              children: [
                if (state.currentIndex > 0)
                  Expanded(
                    flex: 1,
                    child: AppButton(
                      text: 'Previous',
                      icon: Icons.chevron_left_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: () => controller.previousQuestion(),
                    ),
                  ),
                if (state.currentIndex > 0) const SizedBox(width: 10),

                Expanded(
                  flex: 2,
                  child: state.isLastQuestion
                      ? AppButton(
                          text: 'Submit Exam 🎯',
                          icon: Icons.check_circle_outline_rounded,
                          variant: AppButtonVariant.primary,
                          onPressed: () => _showSubmitDialog(context, ref, state),
                        )
                      : AppButton(
                          text: 'Save & Next',
                          icon: Icons.chevron_right_rounded,
                          variant: AppButtonVariant.primary,
                          onPressed: () => controller.nextQuestion(),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmitDialog(
    BuildContext context,
    WidgetRef ref,
    ExamSimulatorState state,
  ) {
    HapticFeedback.mediumImpact();
    final attempted = state.attemptedCount;
    final unattempted = state.unattemptedCount;
    final review = state.markedReviewCount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Ready to Submit Exam?',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Review your attempt status before AI diagnostic evaluation:',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 20),

              // Breakdown Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMetricPill(
                      '$attempted', 'Answered', Colors.green, isDark),
                  _buildMetricPill(
                      '$unattempted', 'Unanswered', Colors.red, isDark),
                  _buildMetricPill(
                      '$review', 'For Review', Colors.purple, isDark),
                ],
              ),
              const SizedBox(height: 26),

              AppButton(
                text: 'Submit & View AI Weakness Radar 🚀',
                variant: AppButtonVariant.primary,
                onPressed: () {
                  Navigator.pop(ctx);
                  final result = ref
                      .read(examSimulatorControllerProvider.notifier)
                      .submitExam(context: context);
                  context.pushReplacement(AppRoutes.examSimulatorResult,
                      extra: result);
                },
              ),
              const SizedBox(height: 10),
              AppButton(
                text: 'Continue Reviewing Questions',
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricPill(
      String count, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuestionPalette(BuildContext context, WidgetRef ref) {
    final state = ref.read(examSimulatorControllerProvider);
    final controller = ref.read(examSimulatorControllerProvider.notifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question Palette',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    child: const Text('Submit Test'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showSubmitDialog(context, ref, state);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Legend
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _buildLegend(Colors.green, 'Answered'),
                  _buildLegend(Colors.grey, 'Unanswered'),
                  _buildLegend(Colors.purple, 'For Review'),
                ],
              ),
              const SizedBox(height: 16),

              // Question Matrix Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.questions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (gridCtx, idx) {
                  final q = state.questions[idx];
                  final isCurrent = state.currentIndex == idx;
                  Color bgColor;
                  Color textColor;

                  if (q.isMarkedForReview) {
                    bgColor = Colors.purple;
                    textColor = Colors.white;
                  } else if (q.isAttempted) {
                    bgColor = Colors.green;
                    textColor = Colors.white;
                  } else {
                    bgColor = isDark ? AppColors.cardDark : const Color(0xFFF1F5F9);
                    textColor = isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight;
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      controller.jumpToQuestion(idx);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.primary
                              : Colors.transparent,
                          width: isCurrent ? 2.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.inter(fontSize: 11)),
      ],
    );
  }
}
