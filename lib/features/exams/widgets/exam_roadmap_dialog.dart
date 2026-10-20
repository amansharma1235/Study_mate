import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/local/preference_service.dart';
import '../../../data/models/exam_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/remote/gemini_service.dart';
import '../../tasks/tasks_controller.dart';

class RoadmapDayItem {
  final int dayNumber;
  final DateTime targetDate;
  final String title;
  final String description;
  final TaskPriority priority;

  RoadmapDayItem({
    required this.dayNumber,
    required this.targetDate,
    required this.title,
    required this.description,
    this.priority = TaskPriority.medium,
  });
}

class ExamRoadmapDialog extends ConsumerStatefulWidget {
  final ExamModel exam;

  const ExamRoadmapDialog({super.key, required this.exam});

  static void show(BuildContext context, ExamModel exam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExamRoadmapDialog(exam: exam),
    );
  }

  @override
  ConsumerState<ExamRoadmapDialog> createState() => _ExamRoadmapDialogState();
}

class _ExamRoadmapDialogState extends ConsumerState<ExamRoadmapDialog> {
  bool _isLoading = true;
  List<RoadmapDayItem> _roadmap = [];
  bool _tasksAdded = false;

  @override
  void initState() {
    super.initState();
    _generateRoadmap();
  }

  Future<void> _generateRoadmap() async {
    setState(() => _isLoading = true);
    final exam = widget.exam;
    final now = DateTime.now();
    final examDate = exam.examDate;
    final totalDays = (examDate.difference(now).inHours / 24).ceil().clamp(1, 30);

    // Try Gemini if configured
    final prefs = ref.read(preferenceServiceProvider);
    final gemini = ref.read(geminiServiceProvider);
    final apiKey = prefs.getAccentTheme(); // test or check if key exists

    List<RoadmapDayItem>? aiGeneratedList;
    try {
      if (apiKey.isNotEmpty && apiKey.startsWith('AIzaSy')) {
        final prompt = '''
Generate an intense, high-yield day-by-day revision roadmap for an upcoming student exam.
Subject: ${exam.subject}
Title: ${exam.title}
Days until exam: $totalDays
Return ONLY a valid JSON array of objects with keys: "day" (int 1..$totalDays), "title" (string, max 6 words), "description" (string, 1 concise sentence).
''';
        final res = await gemini.generateContent(prompt: prompt, apiKey: apiKey);
        final rawText = res.text.replaceAll('```json', '').replaceAll('```', '').trim();
        final jsonArray = jsonDecode(rawText) as List<dynamic>;
        aiGeneratedList = jsonArray.map((item) {
          final dayNum = item['day'] as int? ?? 1;
          final date = now.add(Duration(days: dayNum - 1));
          return RoadmapDayItem(
            dayNumber: dayNum,
            targetDate: date,
            title: item['title'] as String? ?? 'Revision Day $dayNum',
            description: item['description'] as String? ?? 'Core topic review and practice problems.',
            priority: dayNum == totalDays ? TaskPriority.high : (dayNum > totalDays ~/ 2 ? TaskPriority.high : TaskPriority.medium),
          );
        }).toList();
      }
    } catch (_) {
      // Fallback to intelligent academic rule-based roadmap
    }

    if (aiGeneratedList != null && aiGeneratedList.isNotEmpty) {
      _roadmap = aiGeneratedList;
    } else {
      _roadmap = _buildRuleBasedRoadmap(exam, totalDays, now);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<RoadmapDayItem> _buildRuleBasedRoadmap(ExamModel exam, int days, DateTime now) {
    final list = <RoadmapDayItem>[];
    final subj = exam.subject.toLowerCase();

    if (days == 1) {
      list.add(RoadmapDayItem(
        dayNumber: 1,
        targetDate: now,
        title: 'High-Yield Formula & Cheat Sheet Drill',
        description: 'Review summary sheets, essential definitions, and solve 3 previous exam questions.',
        priority: TaskPriority.high,
      ));
      list.add(RoadmapDayItem(
        dayNumber: 1,
        targetDate: now,
        title: 'Timed Mock Drill & Rest Prep',
        description: 'Complete 1 timed speed test, review error log, and pack stationery for tomorrow.',
        priority: TaskPriority.high,
      ));
      return list;
    }

    // Multi-day roadmap
    for (int i = 1; i <= days; i++) {
      final date = now.add(Duration(days: i - 1));
      String title;
      String desc;
      TaskPriority prio = TaskPriority.medium;

      if (i == 1) {
        title = 'Diagnostic & Syllabus Audit';
        desc = 'Map out key chapters in ${exam.subject}, identify high-weightage topics, and gather notes.';
        prio = TaskPriority.medium;
      } else if (i == days) {
        title = 'Exam Eve: Rapid Summary & Mental Readiness';
        desc = 'Flashcard speed review, formula verification, early rest, and exam kit checklist.';
        prio = TaskPriority.high;
      } else if (i == days - 1) {
        title = 'Full-Length Timed Mock Exam';
        desc = 'Simulate real exam timing for ${exam.title}, self-score strictly, and fix weak points.';
        prio = TaskPriority.high;
      } else {
        final phase = i <= (days / 2) ? 'Core Concept Mastery' : 'High-Yield Problem Solving';
        if (subj.contains('math') || subj.contains('phys') || subj.contains('chem') || subj.contains('stat')) {
          desc = 'Practice numericals, theorem proofs, and standard textbook problems.';
        } else if (subj.contains('code') || subj.contains('comput') || subj.contains('prog')) {
          desc = 'Implement core data structures/algorithms and review edge cases.';
        } else {
          desc = 'Create flashcards, review diagrams, and practice short essay explanations.';
        }
        title = 'Day $i: $phase';
        prio = i > (days / 2) ? TaskPriority.high : TaskPriority.medium;
      }

      list.add(RoadmapDayItem(
        dayNumber: i,
        targetDate: date,
        title: title,
        description: desc,
        priority: prio,
      ));
    }
    return list;
  }

  Future<void> _addAllToTasks() async {
    if (_roadmap.isEmpty || _tasksAdded) return;
    AppHaptics.celebration();

    final taskNotifier = ref.read(tasksControllerProvider.notifier);
    for (final item in _roadmap) {
      await taskNotifier.addTask(
        title: '[${widget.exam.subject}] ${item.title}',
        description: '${item.description}\n(Auto-generated AI Revision Roadmap for ${widget.exam.title})',
        dueDate: item.targetDate,
        priority: item.priority,
        subject: widget.exam.subject,
        reminderEnabled: true,
      );
    }

    if (!mounted) return;
    setState(() => _tasksAdded = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Added ${_roadmap.length} revision tasks to your Daily Task Planner!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingDays = DateFormatter.formatRemainingDays(widget.exam.examDate);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.route_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Revision Roadmap 🗺️',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.exam.title} (${widget.exam.subject}) • $remainingDays',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Generating tailored revision blueprint... 🧠',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _roadmap.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _roadmap[index];
                      final isLast = index == _roadmap.length - 1;

                      Color badgeColor = AppColors.primary;
                      if (item.priority == TaskPriority.high) badgeColor = AppColors.error;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF22263A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isLast
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            width: isLast ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'DAY',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: badgeColor,
                                    ),
                                  ),
                                  Text(
                                    '${item.dayNumber}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: badgeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        DateFormatter.formatDate(item.targetDate),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white54 : Colors.black54,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action CTA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: Icon(_tasksAdded ? Icons.check_circle_rounded : Icons.playlist_add_check_rounded),
                  label: Text(
                    _tasksAdded
                        ? 'Roadmap Added to Daily Tasks ✓'
                        : '➕ Add ${_roadmap.length} Days to My Daily Tasks',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tasksAdded ? AppColors.success : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _tasksAdded || _isLoading ? null : _addAllToTasks,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
