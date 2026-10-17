import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../data/models/note_model.dart';
import 'notes_controller.dart';

class NoteDetailScreen extends ConsumerWidget {
  final NoteModel note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Note Details'),
        actions: [
          IconButton(
            icon: Icon(
              note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
            color: note.isPinned ? AppColors.primary : null,
            onPressed: () {
              ref.read(notesControllerProvider.notifier).togglePin(note);
              context.pop();
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              context.push(AppRoutes.editNote, extra: note);
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
            onPressed: () async {
              final confirm = await AppDialogs.showConfirmDialog(
                context: context,
                title: 'Delete Note',
                message:
                    'Are you sure you want to delete "${note.title}"? This action cannot be undone.',
                confirmText: 'Delete',
                isDestructive: true,
              );
              if (confirm == true) {
                await ref
                    .read(notesControllerProvider.notifier)
                    .deleteNote(note.id);
                if (context.mounted) {
                  AppDialogs.showSnackBar(
                    context,
                    message: 'Note deleted',
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
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    note.category,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Updated: ${DateFormatter.formatDateTime(note.updatedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              note.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const Divider(height: 32),
            SelectableText(
              note.content,
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
