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
import '../../../data/local/exam_simulator_service.dart';
import '../../../data/models/exam_simulator_model.dart';
import 'exam_simulator_controller.dart';

class ExamSimulatorConfigScreen extends ConsumerStatefulWidget {
  const ExamSimulatorConfigScreen({super.key});

  @override
  ConsumerState<ExamSimulatorConfigScreen> createState() =>
      _ExamSimulatorConfigScreenState();
}

class _ExamSimulatorConfigScreenState
    extends ConsumerState<ExamSimulatorConfigScreen> {
  final List<String> _subjects = [
    'Computer Science',
    'Physics & Engineering',
    'Mathematics',
    'General Aptitude',
    'Custom AI Topic',
  ];

  String _selectedSubject = 'Computer Science';
  final TextEditingController _customTopicController = TextEditingController();
  int _questionCount = 10;
  int _durationMinutes = 15;
  bool _hasNegativeMarking = true;
  String _difficulty = 'Moderate';
  bool _isGenerating = false;

  @override
  void dispose() {
    _customTopicController.dispose();
    super.dispose();
  }

  Future<void> _startExam() async {
    HapticFeedback.mediumImpact();
    setState(() => _isGenerating = true);

    try {
      final config = ExamSimConfig(
        title: _selectedSubject == 'Custom AI Topic'
            ? (_customTopicController.text.trim().isNotEmpty
                ? _customTopicController.text.trim()
                : 'Custom Topic Mock Test')
            : '$_selectedSubject Mock Exam',
        subject: _selectedSubject == 'Custom AI Topic'
            ? (_customTopicController.text.trim().isNotEmpty
                ? _customTopicController.text.trim()
                : 'General Studies')
            : _selectedSubject,
        durationMinutes: _durationMinutes,
        hasNegativeMarking: _hasNegativeMarking,
        questionCount: _questionCount,
        difficulty: _difficulty,
        customTopic: _selectedSubject == 'Custom AI Topic'
            ? _customTopicController.text.trim()
            : null,
      );

      final service = ref.read(examSimulatorServiceProvider);
      final questions = await service.generateExamQuestions(config: config);

      if (!mounted) return;

      ref.read(examSimulatorControllerProvider.notifier).initExam(config, questions);
      context.push(AppRoutes.examSimulatorPlay);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate exam: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'AI Exam Simulator',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: _isGenerating
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'AI Tutor is Preparing Your Test...',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Formulating high-yield MCQs, balanced subtopics & explanation keys.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Header Card
                  _buildHeroBanner(isDark),
                  const SizedBox(height: 20),

                  // Subject Selection
                  Text(
                    'Select Subject / Domain',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _subjects.map((sub) {
                      final isSelected = _selectedSubject == sub;
                      return ChoiceChip(
                        label: Text(sub),
                        selected: isSelected,
                        labelStyle: GoogleFonts.inter(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight),
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: isDark
                            ? AppColors.cardDark
                            : Colors.white,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedSubject = sub);
                          }
                        },
                      );
                    }).toList(),
                  ),

                  // Custom Topic Field if selected
                  if (_selectedSubject == 'Custom AI Topic') ...[
                    const SizedBox(height: 14),
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: TextField(
                        controller: _customTopicController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Thermodynamics, Flutter Riverpod, Organic Chemistry...',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                          border: InputBorder.none,
                          icon: const Icon(Icons.auto_awesome, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  // Question Count
                  Text(
                    'Number of Questions',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildCountChip(5, '5 Questions\n(Sprint)', isDark),
                      const SizedBox(width: 10),
                      _buildCountChip(10, '10 Questions\n(Standard)', isDark),
                      const SizedBox(width: 10),
                      _buildCountChip(20, '20 Questions\n(Deep Mock)', isDark),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Time Duration Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Time Limit',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_durationMinutes Minutes',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _durationMinutes.toDouble(),
                    min: 5,
                    max: 45,
                    divisions: 8,
                    activeColor: AppColors.primary,
                    label: '$_durationMinutes mins',
                    onChanged: (val) {
                      setState(() => _durationMinutes = val.toInt());
                    },
                  ),

                  const SizedBox(height: 16),

                  // Negative Marking Card
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _hasNegativeMarking,
                      activeThumbColor: AppColors.primary,
                      title: Text(
                        'Competitive Negative Marking Mode',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      subtitle: Text(
                        'JEE / GATE / NEET style: +4 for Correct, -1 for Wrong, 0 for Unattempted.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() => _hasNegativeMarking = val);
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Difficulty Picker
                  Text(
                    'Difficulty Level',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: ['Beginner', 'Moderate', 'Advanced'].map((diff) {
                      final isSelected = _difficulty == diff;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _difficulty = diff),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.cardDark
                                      : Colors.white),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                diff,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // Launch Button
                  AppButton(
                    text: 'Start AI Mock Exam 🚀',
                    icon: Icons.timer_outlined,
                    variant: AppButtonVariant.primary,
                    onPressed: _startExam,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF311042)]
              : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Real Exam Simulator',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'NTA / GATE / JEE Style with AI Weakness Radar',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 6),
                Text(
                  '+50 Scholar XP on test completion',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

  Widget _buildCountChip(int count, String label, bool isDark) {
    final isSelected = _questionCount == count;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _questionCount = count),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : (isDark ? AppColors.cardDark : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
