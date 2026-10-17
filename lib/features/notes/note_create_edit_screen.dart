import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/note_model.dart';
import 'notes_controller.dart';

class NoteCreateEditScreen extends ConsumerStatefulWidget {
  final NoteModel? noteToEdit;

  const NoteCreateEditScreen({super.key, this.noteToEdit});

  @override
  ConsumerState<NoteCreateEditScreen> createState() =>
      _NoteCreateEditScreenState();
}

class _NoteCreateEditScreenState extends ConsumerState<NoteCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'General',
    'Computer Science',
    'Mathematics',
    'Revision',
    'Personal',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.noteToEdit?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.noteToEdit?.content ?? '',
    );
    _selectedCategory = widget.noteToEdit?.category ?? 'General';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (widget.noteToEdit != null) {
        final updated = widget.noteToEdit!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
        );
        await ref.read(notesControllerProvider.notifier).updateNote(updated);
      } else {
        await ref
            .read(notesControllerProvider.notifier)
            .addNote(
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              category: _selectedCategory,
            );
      }

      if (!mounted) return;
      AppDialogs.showSnackBar(
        context,
        message: widget.noteToEdit != null
            ? 'Note updated successfully'
            : 'Note created successfully',
        isSuccess: true,
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnackBar(
        context,
        message: 'Failed to save note: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.noteToEdit != null;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Note' : 'Create Note'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: AppButton(
              text: 'Save',
              isLoading: _isLoading,
              height: 38,
              onPressed: _handleSave,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Note Title',
                hint: 'e.g. Algorithms Lecture 4 Summary',
                controller: _titleController,
                validator: (v) => Validators.validateRequired(v, 'Note title'),
              ),
              const SizedBox(height: AppDimensions.space16),

              Text(
                'Category',
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
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: isDark
                        ? AppColors.surfaceDark
                        : Colors.white,
                    items: _categories.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(
                          c,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space16),

              AppTextField(
                label: 'Note Content',
                hint: 'Type your study notes, key points, formulas...',
                controller: _contentController,
                minLines: 10,
                maxLines: 25,
                validator: (v) =>
                    Validators.validateRequired(v, 'Note content'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
