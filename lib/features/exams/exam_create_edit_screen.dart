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
import '../../data/models/exam_model.dart';
import 'exams_controller.dart';

class ExamCreateEditScreen extends ConsumerStatefulWidget {
  final ExamModel? examToEdit;

  const ExamCreateEditScreen({super.key, this.examToEdit});

  @override
  ConsumerState<ExamCreateEditScreen> createState() =>
      _ExamCreateEditScreenState();
}

class _ExamCreateEditScreenState extends ConsumerState<ExamCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subjectController;
  late TextEditingController _descController;
  late DateTime _examDate;
  late bool _reminderEnabled;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final exam = widget.examToEdit;
    _titleController = TextEditingController(text: exam?.title ?? '');
    _subjectController = TextEditingController(text: exam?.subject ?? '');
    _descController = TextEditingController(text: exam?.description ?? '');
    _examDate = exam?.examDate ?? DateTime.now().add(const Duration(days: 7));
    _reminderEnabled = exam?.reminderEnabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (widget.examToEdit != null) {
        final updated = widget.examToEdit!.copyWith(
          title: _titleController.text.trim(),
          subject: _subjectController.text.trim(),
          description: _descController.text.trim(),
          examDate: _examDate,
          reminderEnabled: _reminderEnabled,
        );
        await ref.read(examsControllerProvider.notifier).updateExam(updated);
      } else {
        await ref
            .read(examsControllerProvider.notifier)
            .addExam(
              title: _titleController.text.trim(),
              subject: _subjectController.text.trim(),
              description: _descController.text.trim(),
              examDate: _examDate,
              reminderEnabled: _reminderEnabled,
            );
      }

      if (!mounted) return;
      AppDialogs.showSnackBar(
        context,
        message: widget.examToEdit != null
            ? 'Exam updated'
            : 'Exam countdown added',
        isSuccess: true,
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnackBar(
        context,
        message: 'Failed to save exam: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.examToEdit != null;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Exam' : 'Add Exam'),
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
                  title: 'Delete Exam',
                  message:
                      'Are you sure you want to remove this exam countdown?',
                  confirmText: 'Delete',
                  isDestructive: true,
                );
                if (confirm == true) {
                  await ref
                      .read(examsControllerProvider.notifier)
                      .deleteExam(widget.examToEdit!.id);
                  if (context.mounted) {
                    AppDialogs.showSnackBar(
                      context,
                      message: 'Exam deleted',
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
                label: 'Exam Title',
                hint: 'e.g. Midterm Examination',
                controller: _titleController,
                validator: (v) => Validators.validateRequired(v, 'Exam title'),
              ),
              const SizedBox(height: AppDimensions.space16),

              AppTextField(
                label: 'Subject / Course',
                hint: 'e.g. Computer Networks',
                controller: _subjectController,
                validator: (v) => Validators.validateRequired(v, 'Subject'),
              ),
              const SizedBox(height: AppDimensions.space16),

              // Date Picker
              Text(
                'Exam Date',
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
                    initialDate: _examDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (picked != null) setState(() => _examDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
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
                        DateFormatter.formatDate(_examDate),
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
              const SizedBox(height: AppDimensions.space16),

              AppTextField(
                label: 'Notes / Topics Covered (Optional)',
                hint: 'e.g. Chapters 1 to 5, bring scientific calculator',
                controller: _descController,
                maxLines: 3,
              ),
              const SizedBox(height: AppDimensions.space16),

              SwitchListTile(
                value: _reminderEnabled,
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Exam Reminder Notification',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Receive a notification reminder before the exam',
                  style: TextStyle(fontSize: 12),
                ),
                onChanged: (val) => setState(() => _reminderEnabled = val),
              ),
              const SizedBox(height: AppDimensions.space32),

              AppButton(
                text: isEditing ? 'Save Changes' : 'Add Exam',
                isLoading: _isLoading,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
