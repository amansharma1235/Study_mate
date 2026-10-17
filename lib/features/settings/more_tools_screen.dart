import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/app_card.dart';

class MoreToolsScreen extends StatefulWidget {
  const MoreToolsScreen({super.key});

  @override
  State<MoreToolsScreen> createState() => _MoreToolsScreenState();
}

class _MoreToolsScreenState extends State<MoreToolsScreen> {
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allTools = [
    // Core Study Tools
    {
      'title': 'Smart Study Planner',
      'subtitle': 'Exam-based session scheduling & conflict detection',
      'icon': Icons.calendar_today_rounded,
      'color': AppColors.primary,
      'route': AppRoutes.planner,
      'category': 'Study Tools',
    },
    {
      'title': 'Flashcards & Spaced Recall',
      'subtitle': 'SM-2 spaced repetition for formulas & concepts',
      'icon': Icons.style_rounded,
      'color': AppColors.secondary,
      'route': AppRoutes.flashcards,
      'category': 'Study Tools',
    },
    {
      'title': 'Syllabus & Revision Tracker',
      'subtitle': 'Chapter progress & automated revision intervals',
      'icon': Icons.menu_book_rounded,
      'color': AppColors.success,
      'route': AppRoutes.syllabus,
      'category': 'Study Tools',
    },
    {
      'title': 'Pomodoro Study Timer',
      'subtitle': 'Focus sessions with deadline timing & breaks',
      'icon': Icons.timer_rounded,
      'color': AppColors.primary,
      'route': AppRoutes.timer,
      'category': 'Study Tools',
    },
    {
      'title': 'Daily Study Habits',
      'subtitle': 'Habit streak tracking & daily goal targets',
      'icon': Icons.local_fire_department_rounded,
      'color': AppColors.warning,
      'route': AppRoutes.habits,
      'category': 'Study Tools',
    },
    {
      'title': 'PDF & Study Documents',
      'subtitle': 'Import lecture slides, books & formula guides',
      'icon': Icons.picture_as_pdf_rounded,
      'color': AppColors.error,
      'route': AppRoutes.documents,
      'category': 'Study Tools',
    },
    {
      'title': 'Voice Notes & Audio Lectures',
      'subtitle': 'Record and replay audio notes & viva summaries',
      'icon': Icons.mic_rounded,
      'color': AppColors.info,
      'route': AppRoutes.voiceNotes,
      'category': 'Study Tools',
    },
    {
      'title': 'Weekly Timetable',
      'subtitle': 'Class schedule with conflict detection',
      'icon': Icons.calendar_month_rounded,
      'color': AppColors.secondary,
      'route': AppRoutes.timetable,
      'category': 'Study Tools',
    },
    {
      'title': 'Exam Countdowns',
      'subtitle': 'Upcoming tests, midterms, and reminders',
      'icon': Icons.alarm_rounded,
      'color': AppColors.error,
      'route': AppRoutes.exams,
      'category': 'Study Tools',
    },
    {
      'title': 'Practice Quizzes & MCQs',
      'subtitle': 'Topic tests with answer explanations',
      'icon': Icons.quiz_rounded,
      'color': AppColors.success,
      'route': AppRoutes.quizCategories,
      'category': 'Study Tools',
    },

    // AI & Advanced Tools
    {
      'title': 'StudyMate AI Tutor',
      'subtitle': 'Concept explainer, quiz generator & note summarizer',
      'icon': Icons.auto_awesome_rounded,
      'color': AppColors.primary,
      'route': AppRoutes.aiAssistant,
      'category': 'AI & Skill Centers',
    },
    {
      'title': 'Coding Practice Center',
      'subtitle': 'DSA roadmaps, practice problems & interview prep',
      'icon': Icons.terminal_rounded,
      'color': AppColors.secondary,
      'route': AppRoutes.coding,
      'category': 'AI & Skill Centers',
    },
    {
      'title': 'Student Career Center',
      'subtitle': 'Resume builder & internship/job application tracker',
      'icon': Icons.work_outline_rounded,
      'color': AppColors.success,
      'route': AppRoutes.career,
      'category': 'AI & Skill Centers',
    },
    {
      'title': 'Collaborative Study Groups',
      'subtitle': 'Shared study plans, notes & group join codes',
      'icon': Icons.groups_rounded,
      'color': AppColors.info,
      'route': AppRoutes.studyGroups,
      'category': 'AI & Skill Centers',
    },

    // Academic Calculators
    {
      'title': 'CGPA & SGPA Calculator',
      'subtitle': 'Course credits weighted grade point calculation',
      'icon': Icons.calculate_rounded,
      'color': AppColors.primary,
      'route': AppRoutes.cgpaCalculator,
      'category': 'Grade Calculators',
    },
    {
      'title': 'Multi-Subject Marks Calculator',
      'subtitle': 'Cumulative marks, percentages & letter grades',
      'icon': Icons.view_list_rounded,
      'color': AppColors.secondary,
      'route': AppRoutes.multiSubjectCalculator,
      'category': 'Grade Calculators',
    },
    {
      'title': 'Percentage Calculator',
      'subtitle': 'Instant single exam percentage',
      'icon': Icons.percent_rounded,
      'color': AppColors.info,
      'route': AppRoutes.percentageCalculator,
      'category': 'Grade Calculators',
    },

    // Insights & Tips
    {
      'title': 'Study Analytics & Insights',
      'subtitle': 'Weekly charts, streaks, and subject distribution',
      'icon': Icons.insights_rounded,
      'color': AppColors.secondary,
      'route': AppRoutes.studyStatistics,
      'category': 'Insights & Tips',
    },
    {
      'title': 'Evidence-Based Study Tips',
      'subtitle': 'Cognitive study techniques for memory retention',
      'icon': Icons.lightbulb_rounded,
      'color': AppColors.warning,
      'route': AppRoutes.studyTips,
      'category': 'Insights & Tips',
    },
    // Settings & Support
    {
      'title': 'Student Profile',
      'subtitle': 'Personal info and daily study goal',
      'icon': Icons.person_rounded,
      'color': AppColors.primary,
      'route': AppRoutes.profile,
      'category': 'Account & Settings',
    },
    {
      'title': 'Appearance & Theme',
      'subtitle': 'Light mode, dark mode, or system default',
      'icon': Icons.palette_rounded,
      'color': AppColors.secondary,
      'route': AppRoutes.appearanceSettings,
      'category': 'Account & Settings',
    },
    {
      'title': 'Notification Settings',
      'subtitle': 'Configure task and exam alerts',
      'icon': Icons.notifications_rounded,
      'color': AppColors.info,
      'route': AppRoutes.notificationSettings,
      'category': 'Account & Settings',
    },
    {
      'title': 'Data Export (JSON)',
      'subtitle': 'Backup your notes, tasks, and study records',
      'icon': Icons.download_rounded,
      'color': AppColors.success,
      'route': AppRoutes.dataExport,
      'category': 'Account & Settings',
    },
    {
      'title': 'Help & Support',
      'subtitle': 'FAQ, usage guides, and support inquiries',
      'icon': Icons.help_outline_rounded,
      'color': AppColors.warning,
      'route': AppRoutes.helpSupport,
      'category': 'Account & Settings',
    },
    {
      'title': 'Privacy Policy',
      'subtitle': 'Data collection and privacy safeguards',
      'icon': Icons.privacy_tip_outlined,
      'color': AppColors.primary,
      'route': AppRoutes.privacyPolicy,
      'category': 'Account & Settings',
    },
    {
      'title': 'Terms and Conditions',
      'subtitle': 'Service usage guidelines',
      'icon': Icons.description_outlined,
      'color': AppColors.secondary,
      'route': AppRoutes.termsConditions,
      'category': 'Account & Settings',
    },
    {
      'title': 'About StudyMate',
      'subtitle': 'App version, mission, and credits',
      'icon': Icons.info_outline_rounded,
      'color': AppColors.info,
      'route': AppRoutes.about,
      'category': 'Account & Settings',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _allTools.where((item) {
      final title = (item['title'] as String).toLowerCase();
      final subtitle = (item['subtitle'] as String).toLowerCase();
      final q = _searchQuery.toLowerCase();
      return title.contains(q) || subtitle.contains(q);
    }).toList();

    final studyTools = filtered
        .where((t) => t['category'] == 'Study Tools')
        .toList();
    final settingsTools = filtered
        .where((t) => t['category'] == 'Account & Settings')
        .toList();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Tools & Utilities',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: 8,
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search tools, calculators, settings...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
              ),
            ),
          ),

          // Tools list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: 8,
              ),
              children: [
                if (studyTools.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                    child: Text(
                      'Study & Productivity',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  ...studyTools.map(
                    (tool) => _buildToolTile(context, tool, isDark),
                  ),
                  const SizedBox(height: 16),
                ],
                if (settingsTools.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                    child: Text(
                      'Account & Preferences',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  ...settingsTools.map(
                    (tool) => _buildToolTile(context, tool, isDark),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolTile(
    BuildContext context,
    Map<String, dynamic> tool,
    bool isDark,
  ) {
    final color = tool['color'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: () => context.push(tool['route'] as String),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Icon(tool['icon'] as IconData, color: color, size: 22),
            ),
            const SizedBox(width: AppDimensions.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool['title'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tool['subtitle'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textMutedLight,
            ),
          ],
        ),
      ),
    );
  }
}
