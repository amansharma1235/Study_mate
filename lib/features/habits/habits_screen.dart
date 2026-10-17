import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/local/app_database.dart';
import '../../data/models/habit_model.dart';
import '../auth/auth_controller.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  List<HabitModel> _habits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final user = ref.read(currentProfileProvider);
    final userId = user?.uid ?? 'guest';
    final db = ref.read(appDatabaseProvider);
    var list = await db.getHabits(userId);

    if (list.isEmpty) {
      final starterHabits = [
        HabitModel(
          id: 'h-1',
          userId: userId,
          title: 'Review 15 Spaced Repetition Flashcards',
          description: 'Solidify memory through active recall',
          colorHex: '#6258E8',
          currentStreak: 4,
          bestStreak: 7,
          targetDaysPerWeek: 7,
        ),
        HabitModel(
          id: 'h-2',
          userId: userId,
          title: 'Complete 2 Pomodoro Focus Sessions',
          description: '50 minutes of deep uninterrupted study',
          colorHex: '#10B981',
          currentStreak: 2,
          bestStreak: 5,
          targetDaysPerWeek: 6,
        ),
        HabitModel(
          id: 'h-3',
          userId: userId,
          title: 'Solve 1 Coding / Math Problem',
          description: 'Keep analytical problem-solving sharp',
          colorHex: '#F59E0B',
          currentStreak: 5,
          bestStreak: 12,
          targetDaysPerWeek: 5,
        ),
      ];

      for (final h in starterHabits) {
        await db.insertHabit(h);
      }
      list = starterHabits;
    }

    if (mounted) {
      setState(() {
        _habits = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleHabit(HabitModel habit) async {
    final updated = habit.toggleToday();
    final db = ref.read(appDatabaseProvider);
    await db.updateHabit(updated);
    _loadHabits();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final completedTodayCount = _habits
        .where((h) => h.isCompletedToday())
        .length;
    final totalHabits = _habits.length;
    final progress = totalHabits > 0
        ? (completedTodayCount / totalHabits)
        : 0.0;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Daily Study Habits',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Habit',
            onPressed: () => _showAddHabitDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Daily Streak & Progress Card
                Container(
                  margin: const EdgeInsets.all(AppDimensions.space16),
                  child: AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today\'s Habit Progress',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$completedTodayCount of $totalHabits habits checked off',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${(progress * 100).toInt()}% Done',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Habit List
                Expanded(
                  child: _habits.isEmpty
                      ? Center(
                          child: Text(
                            'No habits added yet',
                            style: TextStyle(color: AppColors.textMutedLight),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _habits.length,
                          itemBuilder: (context, idx) {
                            final habit = _habits[idx];
                            return _buildHabitCard(habit, isDark);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'New Habit',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        onPressed: () => _showAddHabitDialog(context),
      ),
    );
  }

  Widget _buildHabitCard(HabitModel habit, bool isDark) {
    final isDone = habit.isCompletedToday();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Checkbox
            IconButton(
              icon: Icon(
                isDone
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isDone ? AppColors.success : AppColors.textMutedLight,
                size: 28,
              ),
              onPressed: () => _toggleHabit(habit),
            ),
            const SizedBox(width: 8),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone
                          ? (isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight)
                          : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              size: 12,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${habit.currentStreak}d Streak (Best: ${habit.bestStreak}d)',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Target: ${habit.targetDaysPerWeek}d / wk',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              onPressed: () async {
                await ref.read(appDatabaseProvider).deleteHabit(habit.id);
                _loadHabits();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Create Study Habit',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: titleCtrl,
              label: 'Habit Title',
              hint: 'e.g. Read 20 mins of textbook',
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: descCtrl,
              label: 'Description',
              hint: 'e.g. Daily revision before sleep',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (titleCtrl.text.isEmpty) return;
              final user = ref.read(currentProfileProvider);
              final userId = user?.uid ?? 'guest';
              final newHabit = HabitModel(
                id: 'h-${DateTime.now().millisecondsSinceEpoch}',
                userId: userId,
                title: titleCtrl.text.trim(),
                description: descCtrl.text.trim(),
                targetDaysPerWeek: 7,
              );
              await ref.read(appDatabaseProvider).insertHabit(newHabit);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadHabits();
            },
            child: const Text(
              'Save Habit',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
