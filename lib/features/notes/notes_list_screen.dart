import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/note_model.dart';
import 'notes_controller.dart';

class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notes = ref.watch(filteredNotesProvider);
    final selectedCategory = ref.watch(notesCategoryFilterProvider);
    final searchQuery = ref.watch(notesSearchQueryProvider);

    final categories = [
      'All',
      'General',
      'Computer Science',
      'Mathematics',
      'Revision',
      'Personal',
    ];

    final pinnedNotes = notes.where((n) => n.isPinned).toList();
    final otherNotes = notes.where((n) => !n.isPinned).toList();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'My Notes',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create Note',
            onPressed: () => context.push(AppRoutes.createNote),
          ),
        ],
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
              onChanged: (val) =>
                  ref.read(notesSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search notes by title or content...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => ref
                            .read(notesSearchQueryProvider.notifier)
                            .state = '',
                      )
                    : null,
              ),
            ),
          ),

          // Categories Filter Chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
              ),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = categories[idx];
                final isSelected = selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textPrimaryLight),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                  ),
                  onSelected: (_) {
                    ref.read(notesCategoryFilterProvider.notifier).state = cat;
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Notes Content View
          Expanded(
            child: notes.isEmpty
                ? EmptyState(
                    icon: Icons.note_alt_outlined,
                    title: 'No Notes Found',
                    description: searchQuery.isNotEmpty
                        ? 'No notes match "$searchQuery". Try a different search term or category.'
                        : 'Start organizing your thoughts and study lectures by adding a new note.',
                    buttonText: 'Create Note',
                    onButtonPressed: () => context.push(AppRoutes.createNote),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space16,
                      vertical: 8,
                    ),
                    children: [
                      // Pinned Notes Section
                      if (pinnedNotes.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.push_pin_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'PINNED (${pinnedNotes.length})',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...pinnedNotes.map(
                          (note) => _buildNoteCard(
                            context,
                            ref,
                            note,
                            isDark,
                            isPinnedCard: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Other Notes Section
                      if (pinnedNotes.isNotEmpty && otherNotes.isNotEmpty) ...[
                        Text(
                          'OTHER NOTES (${otherNotes.length})',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      ...otherNotes.map(
                        (note) => _buildNoteCard(
                          context,
                          ref,
                          note,
                          isDark,
                          isPinnedCard: false,
                        ),
                      ),
                      const SizedBox(height: 70), // Bottom padding for FAB
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Create Note',
        child: const Icon(Icons.edit_note_rounded, size: 28),
        onPressed: () => context.push(AppRoutes.createNote),
      ),
    );
  }

  Widget _buildNoteCard(
    BuildContext context,
    WidgetRef ref,
    NoteModel note,
    bool isDark, {
    required bool isPinnedCard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => context.push(AppRoutes.noteDetail, extra: note),
        border: isPinnedCard
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 1.5,
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 18,
                    color: note.isPinned
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight),
                  ),
                  tooltip: note.isPinned ? 'Unpin Note' : 'Pin Note',
                  onPressed: () {
                    ref.read(notesControllerProvider.notifier).togglePin(note);
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              note.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  DateFormatter.formatMonthDay(note.updatedAt),
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
    );
  }
}
