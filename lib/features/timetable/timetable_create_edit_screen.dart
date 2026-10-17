import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/timetable_model.dart';
import 'timetable_controller.dart';

class TimetableCreateEditScreen extends ConsumerStatefulWidget {
  final TimetableModel? entryToEdit;

  const TimetableCreateEditScreen({super.key, this.entryToEdit});

  @override
  ConsumerState<TimetableCreateEditScreen> createState() =>
      _TimetableCreateEditScreenState();
}

class _TimetableCreateEditScreenState
    extends ConsumerState<TimetableCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subjectController;
  late TextEditingController _roomController;
  late TextEditingController _instructorController;

  late int _dayOfWeek;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late Color _selectedColor;
  bool _isLoading = false;

  final List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    final entry = widget.entryToEdit;
    _subjectController = TextEditingController(text: entry?.subject ?? '');
    _roomController = TextEditingController(text: entry?.room ?? '');
    _instructorController = TextEditingController(
      text: entry?.instructor ?? '',
    );
    _dayOfWeek = entry?.dayOfWeek ?? DateTime.now().weekday;

    if (entry != null) {
      final startParts = entry.startTime.split(':');
      _startTime = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );
      final endParts = entry.endTime.split(':');
      _endTime = TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      );
      try {
        final hex = entry.colorHex.replaceAll('#', '');
        _selectedColor = Color(int.parse('0xFF$hex'));
      } catch (_) {
        _selectedColor = AppColors.subjectPalette[0];
      }
    } else {
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 30);
      _selectedColor = AppColors.subjectPalette[0];
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _roomController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate start time is before end time
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (startMinutes >= endMinutes) {
      AppDialogs.showSnackBar(
        context,
        message: 'Class end time must be after start time.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final colorHex =
          '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
      final startTimeStr = _formatTimeOfDay(_startTime);
      final endTimeStr = _formatTimeOfDay(_endTime);

      bool success;
      if (widget.entryToEdit != null) {
        final updated = widget.entryToEdit!.copyWith(
          subject: _subjectController.text.trim(),
          dayOfWeek: _dayOfWeek,
          startTime: startTimeStr,
          endTime: endTimeStr,
          room: _roomController.text.trim(),
          instructor: _instructorController.text.trim(),
          colorHex: colorHex,
        );
        success = await ref
            .read(timetableControllerProvider.notifier)
            .updateClass(updated);
      } else {
        success = await ref
            .read(timetableControllerProvider.notifier)
            .addClass(
              subject: _subjectController.text.trim(),
              dayOfWeek: _dayOfWeek,
              startTime: startTimeStr,
              endTime: endTimeStr,
              room: _roomController.text.trim(),
              instructor: _instructorController.text.trim(),
              colorHex: colorHex,
            );
      }

      if (!mounted) return;

      if (!success) {
        AppDialogs.showSnackBar(
          context,
          message: 'Schedule conflict! Another class is already booked during this time interval.',
          isError: true,
        );
      } else {
        AppDialogs.showSnackBar(
          context,
          message: widget.entryToEdit != null
              ? 'Class updated successfully'
              : 'Class added to schedule',
          isSuccess: true,
        );
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnackBar(
        context,
        message: 'Error saving class: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.entryToEdit != null;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Class' : 'Add Class'),
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
                  title: 'Delete Class',
                  message: 'Are you sure you want to remove this class from your timetable?',
                  confirmText: 'Delete',
                  isDestructive: true,
                );
                if (confirm == true) {
                  await ref
                      .read(timetableControllerProvider.notifier)
                      .deleteClass(widget.entryToEdit!.id);
                  if (context.mounted) {
                    AppDialogs.showSnackBar(
                      context,
                      message: 'Class deleted',
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
                label: 'Subject Name',
                hint: 'e.g. Data Structures & Algorithms',
                controller: _subjectController,
                validator: (v) =>
                    Validators.validateRequired(v, 'Subject name'),
              ),
              const SizedBox(height: AppDimensions.space16),

              // Day of Week
              Text(
                'Day of the Week',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _dayOfWeek,
                    isExpanded: true,
                    dropdownColor: isDark
                        ? AppColors.surfaceDark
                        : Colors.white,
                    items: List.generate(7, (i) {
                      final dayNum = i + 1;
                      return DropdownMenuItem(
                        value: dayNum,
                        child: Text(
                          _dayNames[i],
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) setState(() => _dayOfWeek = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space16),

              // Start & End Time Pickers
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Time',
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
                              initialTime: _startTime,
                            );
                            if (picked != null) {
                              setState(() => _startTime = picked);
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
                                Text(_startTime.format(context)),
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
                          'End Time',
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
                              initialTime: _endTime,
                            );
                            if (picked != null) {
                              setState(() => _endTime = picked);
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
                                Text(_endTime.format(context)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),

              AppTextField(
                label: 'Classroom / Lecture Hall',
                hint: 'e.g. Lab 4B or Hall 102',
                controller: _roomController,
              ),
              const SizedBox(height: AppDimensions.space16),

              AppTextField(
                label: 'Instructor (Optional)',
                hint: 'e.g. Prof. Alan Turing',
                controller: _instructorController,
              ),
              const SizedBox(height: AppDimensions.space20),

              // Subject Color
              Text(
                'Subject Color Tag',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: AppColors.subjectPalette.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.space32),

              AppButton(
                text: isEditing ? 'Save Changes' : 'Add to Schedule',
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
