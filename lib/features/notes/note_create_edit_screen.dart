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
  final String? initialTitle;
  final String? initialContent;

  const NoteCreateEditScreen({
    super.key,
    this.noteToEdit,
    this.initialTitle,
    this.initialContent,
  });

  @override
  ConsumerState<NoteCreateEditScreen> createState() =>
      _NoteCreateEditScreenState();
}

class _NoteCreateEditScreenState extends ConsumerState<NoteCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final FocusNode _contentFocusNode = FocusNode();
  late String _selectedCategory;
  late bool _isPinned;
  bool _isLoading = false;
  bool _hasUnsavedEdits = false;

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
      text: widget.noteToEdit?.title ?? widget.initialTitle ?? '',
    );
    _contentController = TextEditingController(
      text: widget.noteToEdit?.content ?? widget.initialContent ?? '',
    );
    _selectedCategory = widget.noteToEdit?.category ?? 'Revision';
    _isPinned = widget.noteToEdit?.isPinned ?? false;

    if (widget.initialTitle != null || widget.initialContent != null) {
      _hasUnsavedEdits = true;
    }

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_hasUnsavedEdits && mounted) {
      setState(() => _hasUnsavedEdits = true);
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onTextChanged);
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  bool get _isDirty {
    final origTitle = widget.noteToEdit?.title ?? '';
    final origContent = widget.noteToEdit?.content ?? '';
    final origCat = widget.noteToEdit?.category ?? 'General';
    final origPinned = widget.noteToEdit?.isPinned ?? false;

    return _titleController.text.trim() != origTitle.trim() ||
        _contentController.text.trim() != origContent.trim() ||
        _selectedCategory != origCat ||
        _isPinned != origPinned;
  }

  int get _wordCount {
    final text = _contentController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
  }

  int get _charCount => _contentController.text.length;

  int get _readingMinutes => (_wordCount / 200).ceil();

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (widget.noteToEdit != null) {
        final updated = widget.noteToEdit!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          isPinned: _isPinned,
          updatedAt: DateTime.now(),
        );
        await ref.read(notesControllerProvider.notifier).updateNote(updated);
      } else {
        await ref.read(notesControllerProvider.notifier).addNote(
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              category: _selectedCategory,
            );
      }

      _hasUnsavedEdits = false;
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

  Future<bool> _handlePopRequest() async {
    if (!_isDirty) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Unsaved Changes?'),
        content: const Text(
          'You have unsaved changes in this note. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Discard',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.noteToEdit != null;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handlePopRequest();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Note' : 'Create Note'),
          actions: [
            IconButton(
              icon: Icon(
                _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: _isPinned ? AppColors.primary : null,
              ),
              tooltip: _isPinned ? 'Unpin Note' : 'Pin Note to Top',
              onPressed: () {
                setState(() => _isPinned = !_isPinned);
                AppDialogs.showSnackBar(
                  context,
                  message: _isPinned
                      ? 'Note will be pinned to top'
                      : 'Note unpinned',
                  isSuccess: true,
                );
              },
            ),
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
        body: Column(
          children: [
            // Status & Live Metrics Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: (_isDirty ? AppColors.warning : AppColors.success)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isDirty
                              ? Icons.edit_note_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 13,
                          color:
                              _isDirty ? AppColors.warning : AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isLoading
                              ? 'Saving...'
                              : (_isDirty ? 'Unsaved Edits' : 'Saved'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _isDirty
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$_wordCount words • $_charCount chars • ~$_readingMinutes min read',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // Main Editor Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        label: 'Note Title',
                        hint: 'e.g. Distributed Systems & Consensus Proofs',
                        controller: _titleController,
                        validator: (v) =>
                            Validators.validateRequired(v, 'Note title'),
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
                              if (val != null) {
                                setState(() => _selectedCategory = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      Text(
                        'Note Content',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Clean Note Content Area
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextFormField(
                          controller: _contentController,
                          focusNode: _contentFocusNode,
                          minLines: 12,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText:
                                'Type study notes, proofs, key definitions, or paste lecture slides...',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                              fontSize: 14,
                            ),
                          ),
                          validator: (v) =>
                              Validators.validateRequired(v, 'Note content'),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
