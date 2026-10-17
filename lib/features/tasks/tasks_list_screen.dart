import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/task_model.dart';
import 'tasks_controller.dart';

class TasksListScreen extends ConsumerWidget {
  const TasksListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasks = ref.watch(filteredTasksProvider);
    final activeFilter = ref.watch(taskFilterProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Tasks & Homework',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            onPressed: () => context.push(AppRoutes.createTask),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs Segmented Control
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: 8,
            ),
            child: Row(
              children: [
                _buildFilterTab(
                  ref,
                  TaskFilter.all,
                  'All',
                  activeFilter,
                  isDark,
                ),
                const SizedBox(width: 6),
                _buildFilterTab(
                  ref,
                  TaskFilter.today,
                  'Today',
                  activeFilter,
                  isDark,
                ),
                const SizedBox(width: 6),
                _buildFilterTab(
                  ref,
                  TaskFilter.upcoming,
                  'Upcoming',
                  activeFilter,
                  isDark,
                ),
                const SizedBox(width: 6),
                _buildFilterTab(
                  ref,
                  TaskFilter.completed,
                  'Done',
                  activeFilter,
                  isDark,
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: 4,
            ),
            child: TextField(
              onChanged: (val) =>
                  ref.read(taskSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search tasks or subjects...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Task List
          Expanded(
            child: tasks.isEmpty
                ? EmptyState(
                    icon: Icons.checklist_rounded,
                    title: 'No Tasks Found',
                    description: 'Keep track of your homework assignments and project milestones.',
                    buttonText: 'Add Task',
                    onButtonPressed: () => context.push(AppRoutes.createTask),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space16,
                      vertical: 8,
                    ),
                    itemCount: tasks.length,
                    itemBuilder: (context, idx) {
                      final task = tasks[idx];
                      return _buildTaskCard(context, ref, task, isDark);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 28),
        onPressed: () => context.push(AppRoutes.createTask),
      ),
    );
  }

  Widget _buildFilterTab(
    WidgetRef ref,
    TaskFilter filter,
    String label,
    TaskFilter current,
    bool isDark,
  ) {
    final isSelected = filter == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(taskFilterProvider.notifier).state = filter,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textPrimaryLight),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
    bool isDark,
  ) {
    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.high:
        priorityColor = AppColors.error;
        break;
      case TaskPriority.medium:
        priorityColor = AppColors.warning;
        break;
      case TaskPriority.low:
        priorityColor = AppColors.success;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => context.push(AppRoutes.editTask, extra: task),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox
            Transform.scale(
              scale: 1.1,
              child: Checkbox(
                value: task.isCompleted,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (_) {
                  ref.read(tasksControllerProvider.notifier).toggleTask(task);
                },
              ),
            ),
            const SizedBox(width: 8),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.isCompleted
                          ? (isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight)
                          : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task.priority.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: priorityColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        task.subject,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const Spacer(),
                      if (task.isOverdue)
                        const Text(
                          'Overdue',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        )
                      else
                        Text(
                          DateFormatter.formatMonthDay(task.dueDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
