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
import '../../../data/models/exam_simulator_model.dart';

class ExamSimulatorResultScreen extends ConsumerStatefulWidget {
  final ExamSimResult result;

  const ExamSimulatorResultScreen({super.key, required this.result});

  @override
  ConsumerState<ExamSimulatorResultScreen> createState() =>
      _ExamSimulatorResultScreenState();
}

class _ExamSimulatorResultScreenState
    extends ConsumerState<ExamSimulatorResultScreen> {
  int? _expandedQuestionIndex;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final minutes = result.totalTimeSpentSeconds ~/ 60;
    final seconds = result.totalTimeSpentSeconds % 60;
    final timeStr = '${minutes}m ${seconds}s';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Exam Analysis & Radar',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Score Card
            _buildHeroScoreCard(result, isDark),
            const SizedBox(height: 20),

            // Key Statistics Row
            _buildStatSummary(result, timeStr, isDark),
            const SizedBox(height: 20),

            // AI Weakness Radar & Diagnosis
            _buildAiWeaknessRadar(result, isDark),
            const SizedBox(height: 24),

            // Detailed Solution Key & Question Review
            Text(
              'Question Review & Solutions',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),

            ...List.generate(result.questions.length, (idx) {
              final q = result.questions[idx];
              final isExpanded = _expandedQuestionIndex == idx;
              final isAttempted = q.isAttempted;
              final isCorrect = q.isCorrect;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _expandedQuestionIndex =
                                isExpanded ? null : idx;
                          });
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: !isAttempted
                                    ? Colors.grey.withValues(alpha: 0.15)
                                    : (isCorrect
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : Colors.red.withValues(alpha: 0.15)),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  !isAttempted
                                      ? Icons.remove_rounded
                                      : (isCorrect
                                          ? Icons.check_rounded
                                          : Icons.close_rounded),
                                  size: 18,
                                  color: !isAttempted
                                      ? Colors.grey
                                      : (isCorrect
                                          ? Colors.green
                                          : Colors.red),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Q${idx + 1} • ${q.subtopic}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    q.question,
                                    maxLines: isExpanded ? null : 1,
                                    overflow: isExpanded
                                        ? TextOverflow.visible
                                        : TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),

                      if (isExpanded) ...[
                        const Divider(height: 24),
                        // Options Breakdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(q.options.length, (optIdx) {
                            final isUserSelected =
                                q.selectedOptionIndex == optIdx;
                            final isActualCorrect = q.correctIndex == optIdx;

                            Color optBorderColor = Colors.transparent;
                            Color optBgColor = isDark
                                ? AppColors.surfaceDark
                                : const Color(0xFFF8FAFC);
                            Widget? tag;

                            if (isActualCorrect) {
                              optBorderColor = Colors.green;
                              optBgColor = Colors.green.withValues(alpha: 0.1);
                              tag = _buildOptionBadge('Correct', Colors.green);
                            } else if (isUserSelected && !isActualCorrect) {
                              optBorderColor = Colors.red;
                              optBgColor = Colors.red.withValues(alpha: 0.1);
                              tag = _buildOptionBadge('Your Pick', Colors.red);
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: optBgColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: optBorderColor,
                                  width: optBorderColor != Colors.transparent
                                      ? 1.5
                                      : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${String.fromCharCode(65 + optIdx)}. ',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      color: isActualCorrect
                                          ? Colors.green
                                          : (isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimaryLight),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      q.options[optIdx],
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                  ),
                                  ?tag,
                                ],
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 10),

                        // Solution Explanation Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.lightbulb_outline_rounded,
                                      size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Explanation:',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                q.explanation,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Bottom CTA Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Retake Mock Test 🚀',
                    icon: Icons.refresh_rounded,
                    variant: AppButtonVariant.primary,
                    onPressed: () => context.pushReplacement(
                        AppRoutes.examSimulatorConfig),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Dashboard 🏠',
                    icon: Icons.home_rounded,
                    variant: AppButtonVariant.outline,
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroScoreCard(ExamSimResult result, bool isDark) {
    String verdict = 'Distinction Scholar 🎖️';
    Color verdictColor = Colors.greenAccent;
    if (result.percentage < 40) {
      verdict = 'Needs Revision 📚';
      verdictColor = Colors.orangeAccent;
    } else if (result.percentage < 70) {
      verdict = 'Good Effort 🥈';
      verdictColor = Colors.amberAccent;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF2E1065)]
              : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              verdict,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: verdictColor,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Net Score Text
          Text(
            '${result.scoreObtained.toStringAsFixed(result.scoreObtained.truncateToDouble() == result.scoreObtained ? 0 : 1)} / ${result.maxPossibleScore.toInt()}',
            style: GoogleFonts.outfit(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            'Net Marks (${result.percentage.toStringAsFixed(1)}%)',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),

          // Scholar XP Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.military_tech_rounded,
                    color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text(
                  '+50 Scholar XP Claimed!',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatSummary(ExamSimResult result, String timeStr, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Correct', '${result.correctCount}', Colors.green),
          _buildStatDivider(isDark),
          _buildStatItem('Wrong', '${result.incorrectCount}', Colors.red),
          _buildStatDivider(isDark),
          _buildStatItem('Skipped', '${result.unattemptedCount}', Colors.grey),
          _buildStatDivider(isDark),
          _buildStatItem('Time', timeStr, AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1,
      height: 30,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }

  Widget _buildAiWeaknessRadar(ExamSimResult result, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.radar_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Weakness Diagnosis Radar',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Subtopic mastery & retention analysis',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Subtopic Progress Bars
          ...result.subtopicBreakdown.map((sub) {
            Color barColor = Colors.green;
            if (sub.accuracy < 40) {
              barColor = Colors.red;
            } else if (sub.accuracy < 70) {
              barColor = Colors.amber;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        sub.subtopic,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        '${sub.correctCount}/${sub.totalQuestions} (${sub.accuracy.toStringAsFixed(0)}%)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: barColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: sub.accuracy / 100,
                      backgroundColor:
                          isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // Actionable AI Prescription
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates_rounded,
                    color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.aiDiagnosis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
