import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/timetable_model.dart';
import '../../gamification/gamification_controller.dart';
import '../../tasks/tasks_controller.dart';

enum _TimelineFilter { all, classes, tasks }

enum _TimelineItemType { classSession, taskDeadline }

class _TimelineItem {
  final String id;
  final String title;
  final String subtitle;
  final String? room;
  final String? instructor;
  final String timeDisplay;
  final int startMinutes;
  final int endMinutes;
  final _TimelineItemType type;
  final Color accentColor;
  final bool isCompleted;
  final bool isOverdue;
  final bool isLiveNow;
  final dynamic rawModel;

  const _TimelineItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.room,
    this.instructor,
    required this.timeDisplay,
    required this.startMinutes,
    required this.endMinutes,
    required this.type,
    required this.accentColor,
    required this.isCompleted,
    this.isOverdue = false,
    required this.isLiveNow,
    required this.rawModel,
  });
}

class TodayVisualTimelineCard extends ConsumerStatefulWidget {
  final List<TimetableModel> todayClasses;
  final List<TaskModel> todayTasks;

  const TodayVisualTimelineCard({
    super.key,
    required this.todayClasses,
    required this.todayTasks,
  });

  @override
  ConsumerState<TodayVisualTimelineCard> createState() =>
      _TodayVisualTimelineCardState();
}

class _TodayVisualTimelineCardState
    extends ConsumerState<TodayVisualTimelineCard> {
  _TimelineFilter _selectedFilter = _TimelineFilter.all;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    // Build timeline items
    final List<_TimelineItem> items = [];

    // 1. Classes from Timetable
    for (final c in widget.todayClasses) {
      final isLive =
          currentMinutes >= c.startMinutes && currentMinutes <= c.endMinutes;
      final isPast = currentMinutes > c.endMinutes;

      Color color;
      try {
        final hex = c.colorHex.replaceAll('#', '');
        color = Color(int.parse('FF$hex', radix: 16));
      } catch (_) {
        color = AppColors.primary;
      }

      items.add(
        _TimelineItem(
          id: 'class_${c.id}',
          title: c.subject,
          subtitle: c.room.isNotEmpty
              ? 'Room ${c.room}${c.instructor.isNotEmpty ? " • Prof. ${c.instructor}" : ""}'
              : (c.instructor.isNotEmpty
                  ? 'Prof. ${c.instructor}'
                  : 'Class Lecture'),
          room: c.room,
          instructor: c.instructor,
          timeDisplay: '${c.startTime} - ${c.endTime}',
          startMinutes: c.startMinutes,
          endMinutes: c.endMinutes,
          type: _TimelineItemType.classSession,
          accentColor: color,
          isCompleted: isPast,
          isLiveNow: isLive,
          rawModel: c,
        ),
      );
    }

    // 2. Tasks Due Today / Overdue
    for (final t in widget.todayTasks) {
      final taskMinutes = t.dueDate.hour * 60 + t.dueDate.minute;
      final timeStr = DateFormatter.formatTime(t.dueDate);

      Color color;
      switch (t.priority) {
        case TaskPriority.high:
          color = AppColors.error;
          break;
        case TaskPriority.medium:
          color = AppColors.secondary;
          break;
        case TaskPriority.low:
          color = AppColors.success;
          break;
      }

      items.add(
        _TimelineItem(
          id: 'task_${t.id}',
          title: t.title,
          subtitle: t.subject.isNotEmpty ? t.subject : 'Task Assignment',
          timeDisplay: 'Due $timeStr',
          startMinutes: taskMinutes,
          endMinutes: taskMinutes + 30,
          type: _TimelineItemType.taskDeadline,
          accentColor: color,
          isCompleted: t.isCompleted,
          isOverdue: t.isOverdue,
          isLiveNow: false,
          rawModel: t,
        ),
      );
    }

    // Sort chronologically by startMinutes
    items.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    // Filter items
    final filteredItems = items.where((item) {
      if (_selectedFilter == _TimelineFilter.classes) {
        return item.type == _TimelineItemType.classSession;
      }
      if (_selectedFilter == _TimelineFilter.tasks) {
        return item.type == _TimelineItemType.taskDeadline;
      }
      return true;
    }).toList();

    final liveCount = items.where((i) => i.isLiveNow).length;
    final totalCount = items.length;
    final completedCount = items.where((i) => i.isCompleted).length;

    // Show top 3 unless expanded
    final displayItems = _isExpanded
        ? filteredItems
        : filteredItems.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.view_timeline_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Today's Schedule",
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    letterSpacing: -0.3,
                  ),
                ),
                if (liveCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            // Quick Add Action
            PopupMenuButton<String>(
              tooltip: 'Add to Schedule',
              icon: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.primaryLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              color: isDark ? AppColors.cardDark : Colors.white,
              onSelected: (val) {
                if (val == 'class') {
                  context.push(AppRoutes.addClass);
                } else if (val == 'task') {
                  context.push(AppRoutes.createTask);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'class',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text('Add Class to Timetable'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'task',
                  child: Row(
                    children: [
                      Icon(Icons.checklist_rounded,
                          size: 18, color: AppColors.success),
                      SizedBox(width: 10),
                      Text('Add Due Task'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Filter Pills & Summary Counter
        Row(
          children: [
            _buildFilterChip(
              context,
              label: 'All ($totalCount)',
              filter: _TimelineFilter.all,
              isSelected: _selectedFilter == _TimelineFilter.all,
            ),
            const SizedBox(width: 6),
            _buildFilterChip(
              context,
              label: 'Classes (${widget.todayClasses.length})',
              filter: _TimelineFilter.classes,
              isSelected: _selectedFilter == _TimelineFilter.classes,
            ),
            const SizedBox(width: 6),
            _buildFilterChip(
              context,
              label: 'Tasks (${widget.todayTasks.length})',
              filter: _TimelineFilter.tasks,
              isSelected: _selectedFilter == _TimelineFilter.tasks,
            ),
            const Spacer(),
            if (totalCount > 0)
              Text(
                '$completedCount/$totalCount Done',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Main Visual Timeline Container
        if (filteredItems.isEmpty)
          _buildEmptyTimelineState(context, isDark)
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 2),
                  itemBuilder: (context, index) {
                    final item = displayItems[index];
                    final isLast = index == displayItems.length - 1;
                    return _buildTimelineRow(
                      context,
                      item: item,
                      isLast: isLast,
                      isDark: isDark,
                    );
                  },
                ),

                // Expand/Collapse Button if more than 3 items
                if (filteredItems.length > 3) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isExpanded
                                ? 'Show Less'
                                : 'View all ${filteredItems.length} items',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required _TimelineFilter filter,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark
                  ? AppColors.surfaceDark
                  : AppColors.primaryLight.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textPrimaryLight),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineRow(
    BuildContext context, {
    required _TimelineItem item,
    required bool isLast,
    required bool isDark,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Time Track & Connected Line
          SizedBox(
            width: 62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  item.timeDisplay.split(' - ').first,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: item.isLiveNow
                        ? AppColors.secondary
                        : (item.isCompleted
                            ? (isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight)
                            : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight)),
                  ),
                ),
                if (item.timeDisplay.contains(' - '))
                  Text(
                    item.timeDisplay.split(' - ').last,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
              ],
            ),
          ),

          // Middle: Visual Node & Vertical Line
          Column(
            children: [
              const SizedBox(height: 10),
              // Node Circle
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isLiveNow
                      ? AppColors.secondary
                      : (item.isCompleted
                          ? AppColors.success
                          : item.accentColor.withValues(alpha: 0.15)),
                  border: Border.all(
                    color: item.isLiveNow
                        ? Colors.white
                        : (item.isCompleted
                            ? AppColors.success
                            : item.accentColor),
                    width: item.isLiveNow ? 2.5 : 2,
                  ),
                  boxShadow: item.isLiveNow
                      ? [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.45),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: item.isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          size: 11,
                          color: Colors.white,
                        )
                      : (item.isLiveNow
                          ? Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            )
                          : null),
                ),
              ),
              // Connecting Vertical Track Line
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: item.isCompleted
                          ? AppColors.success.withValues(alpha: 0.3)
                          : (isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // Right: Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: item.isLiveNow
                      ? AppColors.secondary.withValues(alpha: isDark ? 0.12 : 0.08)
                      : (isDark
                          ? AppColors.surfaceDark.withValues(alpha: 0.7)
                          : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: item.isLiveNow
                        ? AppColors.secondary.withValues(alpha: 0.4)
                        : (isDark
                            ? AppColors.borderDark.withValues(alpha: 0.5)
                            : AppColors.borderLight.withValues(alpha: 0.7)),
                    width: item.isLiveNow ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Type Pill & Live Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: item.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.type == _TimelineItemType.classSession
                                    ? Icons.school_rounded
                                    : Icons.assignment_outlined,
                                size: 11,
                                color: item.accentColor,
                              ),
                              const SizedBox(width: 3.5),
                              Text(
                                item.type == _TimelineItemType.classSession
                                    ? 'CLASS'
                                    : (item.isOverdue ? 'OVERDUE' : 'TASK'),
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: item.isOverdue
                                      ? AppColors.error
                                      : item.accentColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item.isLiveNow)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'HAPPENING NOW',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          )
                        else if (item.type == _TimelineItemType.classSession)
                          InkWell(
                            onTap: () {
                              context.push(
                                AppRoutes.timer,
                                extra: {
                                  'preselectedSubject': item.title,
                                },
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    size: 11,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Focus ⏱️',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Title & Interactive Checkbox (if Task)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (item.type == _TimelineItemType.taskDeadline) ...[
                          GestureDetector(
                            onTap: () async {
                              final task = item.rawModel as TaskModel;
                              await ref
                                  .read(tasksControllerProvider.notifier)
                                  .toggleTask(task);

                              if (!task.isCompleted && context.mounted) {
                                await ref
                                    .read(gamificationControllerProvider.notifier)
                                    .recordTaskCompleted(context);
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: item.isCompleted
                                    ? AppColors.success
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: item.isCompleted
                                      ? AppColors.success
                                      : (isDark
                                          ? AppColors.borderDark
                                          : AppColors.textMutedLight),
                                  width: 1.6,
                                ),
                              ),
                              child: item.isCompleted
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              decoration: item.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.isCompleted
                                  ? (isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight)
                                  : (isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    // Subtitle Details (Room, Instructor or Subject)
                    Text(
                      item.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTimelineState(BuildContext context, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.wb_sunny_outlined,
              size: 28,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your Schedule is Clear Today!',
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No upcoming lectures or due tasks for today. Plan ahead to stay in the Scholar flow.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.addClass),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('+ Add Class'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.createTask),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('+ Add Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
