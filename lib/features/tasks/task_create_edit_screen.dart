import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/task_model.dart';
import 'tasks_controller.dart';

class TaskCreateEditScreen extends ConsumerStatefulWidget {
  final TaskModel? taskToEdit;

  const TaskCreateEditScreen({super.key, this.taskToEdit});

  @override
  ConsumerState<TaskCreateEditScreen> createState() =>
      _TaskCreateEditScreenState();
}

class _TaskCreateEditScreenState extends ConsumerState<TaskCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _subjectController;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  late TaskPriority _priority;
  late bool _reminderEnabled;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _subjectController = TextEditingController(
      text: task?.subject ?? 'General',
    );
    _dueDate = task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _dueTime = TimeOfDay(hour: _dueDate.hour, minute: _dueDate.minute);
    _priority = task?.priority ?? TaskPriority.medium;
    _reminderEnabled = task?.reminderEnabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final combinedDateTime = DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        _dueTime.hour,
        _dueTime.minute,
      );

      if (widget.taskToEdit != null) {
        final updated = widget.taskToEdit!.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          subject: _subjectController.text.trim(),
          dueDate: combinedDateTime,
          priority: _priority,
          reminderEnabled: _reminderEnabled,
        );
        await ref.read(tasksControllerProvider.notifier).updateTask(updated);
      } else {
        await ref
            .read(tasksControllerProvider.notifier)
            .addTask(
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              subject: _subjectController.text.trim(),
              dueDate: combinedDateTime,
              priority: _priority,
              reminderEnabled: _reminderEnabled,
            );
      }

      if (!mounted) return;
      AppDialogs.showSnackBar(
        context,
        message: widget.taskToEdit != null ? 'Task updated' : 'Task added',
        isSuccess: true,
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnackBar(
        context,
        message: 'Failed to save task: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.taskToEdit != null;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Add Task'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
              onPressed: () async {
                final confirm = await AppDialogs.showConfirmDialog(
                  context: context,
                  title: 'Delete Task',
                  message: 'Are you sure you want to delete this task?',
                  confirmText: 'Delete',
                  isDestructive: true,
                );
                if (confirm == true) {
                  await ref
                      .read(tasksControllerProvider.notifier)
                      .deleteTask(widget.taskToEdit!.id);
                  if (context.mounted) {
                    AppDialogs.showSnackBar(
                      context,
                      message: 'Task deleted',
                      isSuccess: true,
                    );
                    context.pop();
                  }
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Task Title',
                hint: 'e.g. Complete Discrete Math Assignment 3',
                controller: _titleController,
                validator: (v) => Validators.validateRequired(v, 'Task title'),
              ),
              const SizedBox(height: AppDimensions.space16),

              AppTextField(
                label: 'Subject / Course',
                hint: 'e.g. Computer Science',
                controller: _subjectController,
                validator: (v) => Validators.validateRequired(v, 'Subject'),
              ),
              const SizedBox(height: AppDimensions.space16),

              AppTextField(
                label: 'Description (Optional)',
                hint: 'Additional notes, submission links, instructions...',
                controller: _descController,
                maxLines: 3,
              ),
              const SizedBox(height: AppDimensions.space16),

              // Due Date & Time Picker Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due Date',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dueDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 30),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 730),
                              ),
                            );
                            if (picked != null) {
                              setState(() => _dueDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMedium,
                              ),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormatter.formatMonthDay(_dueDate),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due Time',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _dueTime,
                            );
                            if (picked != null) {
                              setState(() => _dueTime = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMedium,
                              ),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _dueTime.format(context),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space20),

              // Priority Selector
              Text(
                'Priority Level',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPriorityChip(
                    TaskPriority.low,
                    'Low',
                    AppColors.success,
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildPriorityChip(
                    TaskPriority.medium,
                    'Medium',
                    AppColors.warning,
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildPriorityChip(
                    TaskPriority.high,
                    'High',
                    AppColors.error,
                    isDark,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space20),

              // Reminder Toggle
              SwitchListTile(
                value: _reminderEnabled,
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Local Notification Reminder',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Receive a reminder on your device before deadline',
                  style: TextStyle(fontSize: 12),
                ),
                onChanged: (val) => setState(() => _reminderEnabled = val),
              ),
              const SizedBox(height: AppDimensions.space32),

              AppButton(
                text: isEditing ? 'Save Changes' : 'Add Task',
                isLoading: _isLoading,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(
    TaskPriority priority,
    String label,
    Color color,
    bool isDark,
  ) {
    final isSelected = _priority == priority;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = priority),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : (isDark ? AppColors.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: isSelected
                  ? color
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? color
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textPrimaryLight),
            ),
          ),
        ),
      ),
    );
  }
}
