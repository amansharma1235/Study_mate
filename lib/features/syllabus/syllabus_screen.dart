import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../data/models/syllabus_model.dart';
import 'syllabus_controller.dart';

class SyllabusScreen extends ConsumerWidget {
  const SyllabusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topicsAsync = ref.watch(syllabusTopicsProvider);
    final selectedFilter = ref.watch(syllabusSubjectFilterProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Syllabus & Revision Tracker',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Topic',
            onPressed: () => _showAddTopicDialog(context, ref),
          ),
        ],
      ),
      body: topicsAsync.when(
        loading: () => const LoadingSkeletonList(count: 4),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (allTopics) {
          if (allTopics.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'No Syllabus Topics Added',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track your chapters, syllabus progress, and automated revision cycles across your subjects.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      text: 'Load Starter Syllabus',
                      icon: Icons.download_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: () async {
                        await ref
                            .read(syllabusTopicsProvider.notifier)
                            .seedStarterSyllabus();
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          // Statistics
          final completedCount = allTopics
              .where((t) => t.status == 'completed')
              .length;
          final inProgressCount = allTopics
              .where((t) => t.status == 'in_progress')
              .length;
          final totalCount = allTopics.length;
          final percent = totalCount > 0 ? (completedCount / totalCount) : 0.0;

          // Unique subjects
          final subjects = ['All', ...allTopics.map((t) => t.subject).toSet()];

          final displayedTopics = selectedFilter == 'All'
              ? allTopics
              : allTopics.where((t) => t.subject == selectedFilter).toList();

          return Column(
            children: [
              // Overall Progress Card
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
                                'Overall Completion',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$completedCount of $totalCount Topics Completed',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${(percent * 100).toInt()}%',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 10,
                          backgroundColor: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniStat(
                            'Completed',
                            '$completedCount',
                            AppColors.success,
                          ),
                          _buildMiniStat(
                            'In Progress',
                            '$inProgressCount',
                            Colors.orange,
                          ),
                          _buildMiniStat(
                            'Pending',
                            '${totalCount - completedCount - inProgressCount}',
                            AppColors.textMutedLight,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Subject Filter Strip
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: subjects.length,
                  itemBuilder: (context, i) {
                    final sub = subjects[i];
                    final isSel = sub == selectedFilter;

                    return GestureDetector(
                      onTap: () {
                        ref.read(syllabusSubjectFilterProvider.notifier).state =
                            sub;
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primary
                              : (isDark ? AppColors.cardDark : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel
                                ? AppColors.primary
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Text(
                          sub,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isSel
                                ? Colors.white
                                : (isDark
                                      ? Colors.white
                                      : AppColors.textPrimaryLight),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Topics List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space16,
                    vertical: 8,
                  ),
                  itemCount: displayedTopics.length,
                  itemBuilder: (context, idx) {
                    final topic = displayedTopics[idx];
                    return _buildTopicCard(context, ref, topic, isDark);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Topic',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        onPressed: () => _showAddTopicDialog(context, ref),
      ),
    );
  }

  Widget _buildMiniStat(String label, String count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildTopicCard(
    BuildContext context,
    WidgetRef ref,
    SyllabusTopicModel topic,
    bool isDark,
  ) {
    final statusColor = topic.status == 'completed'
        ? AppColors.success
        : (topic.status == 'in_progress'
              ? Colors.orange
              : AppColors.textMutedLight);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Subject / Chapter Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${topic.subject} • ${topic.chapter}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),

                // Status Badge Dropdown
                PopupMenuButton<String>(
                  onSelected: (val) {
                    ref
                        .read(syllabusTopicsProvider.notifier)
                        .updateStatus(topic, val);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'not_started',
                      child: Text('Not Started'),
                    ),
                    const PopupMenuItem(
                      value: 'in_progress',
                      child: Text('In Progress'),
                    ),
                    const PopupMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Text(
                          topic.status.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 16,
                          color: statusColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              topic.title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),

            // Revision stats & action button
            Row(
              children: [
                Icon(
                  Icons.repeat_rounded,
                  size: 15,
                  color: AppColors.textMutedLight,
                ),
                const SizedBox(width: 4),
                Text(
                  'Revised: ${topic.revisionCount} times',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const Spacer(),

                // Mark Revised Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 14),
                  label: const Text(
                    'Mark Revised',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    ref
                        .read(syllabusTopicsProvider.notifier)
                        .markRevised(topic);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ Revised "${topic.title}"! Next reminder scheduled in 7 days.',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTopicDialog(BuildContext context, WidgetRef ref) {
    final subCtrl = TextEditingController();
    final chapCtrl = TextEditingController();
    final titleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Add Syllabus Topic',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: subCtrl,
              label: 'Subject',
              hint: 'e.g. Mathematics',
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: chapCtrl,
              label: 'Chapter',
              hint: 'e.g. Calculus',
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: titleCtrl,
              label: 'Topic Name',
              hint: 'e.g. Integration by Parts',
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
              if (subCtrl.text.isEmpty || titleCtrl.text.isEmpty) return;
              await ref
                  .read(syllabusTopicsProvider.notifier)
                  .addTopic(
                    subject: subCtrl.text.trim(),
                    chapter: chapCtrl.text.trim().isEmpty
                        ? 'General'
                        : chapCtrl.text.trim(),
                    title: titleCtrl.text.trim(),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text(
              'Add Topic',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
