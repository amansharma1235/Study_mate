import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/study_tip_model.dart';
import 'study_tips_controller.dart';

class StudyTipsScreen extends ConsumerWidget {
  const StudyTipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tips = ref.watch(filteredTipsProvider);
    final selectedCategory = ref.watch(selectedTipCategoryProvider);

    final categories = [
      'All',
      'Learning Method',
      'Memory',
      'Exam Prep',
      'Focus',
      'Time Management',
      'Wellness',
    ];

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Study Tips & Habits',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_rounded),
            tooltip: 'Saved Tips',
            onPressed: () => context.push(AppRoutes.savedTips),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category selector chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: 6,
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
                    ref.read(selectedTipCategoryProvider.notifier).state = cat;
                  },
                );
              },
            ),
          ),

          // Tips list
          Expanded(
            child: tips.isEmpty
                ? const EmptyState(
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'No Tips Found',
                    description: 'Check back soon for more evidence-based study recommendations.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    itemCount: tips.length,
                    itemBuilder: (context, idx) {
                      final tip = tips[idx];
                      return _buildTipCard(context, ref, tip, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(
    BuildContext context,
    WidgetRef ref,
    StudyTipModel tip,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tip.category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    tip.isFavorite
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: tip.isFavorite
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight),
                  ),
                  onPressed: () {
                    ref
                        .read(studyTipsControllerProvider.notifier)
                        .toggleFavorite(tip);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tip.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tip.summary,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tip.content,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
