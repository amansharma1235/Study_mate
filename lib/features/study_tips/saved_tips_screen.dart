import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import 'study_tips_controller.dart';

class SavedTipsScreen extends ConsumerWidget {
  const SavedTipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final savedTipsAsync = ref.watch(savedTipsProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Saved Tips & Habits')),
      body: savedTipsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text('Error loading saved tips: $err')),
        data: (saved) {
          if (saved.isEmpty) {
            return const EmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'No Saved Tips',
              description: 'Tap the bookmark icon on any study tip to save it here for quick reference.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.space16),
            itemCount: saved.length,
            itemBuilder: (context, idx) {
              final tip = saved[idx];
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
                            icon: const Icon(
                              Icons.bookmark_rounded,
                              color: AppColors.primary,
                            ),
                            onPressed: () async {
                              await ref
                                  .read(studyTipsControllerProvider.notifier)
                                  .toggleFavorite(tip);
                              ref.invalidate(savedTipsProvider);
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
            },
          );
        },
      ),
    );
  }
}
