import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/loading_skeleton.dart';
import 'flashcards_controller.dart';

class FlashcardsScreen extends ConsumerWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final decksAsync = ref.watch(flashcardDecksProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Spaced Repetition Flashcards',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create Deck',
            onPressed: () => _showCreateDeckDialog(context, ref),
          ),
        ],
      ),
      body: decksAsync.when(
        loading: () => const LoadingSkeletonList(count: 3),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (decks) {
          if (decks.isEmpty) {
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
                        Icons.style_rounded,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'No Flashcard Decks Yet',
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
                      'Create custom decks or load pre-built starter decks to memorize formulas, algorithms, and definitions using spaced repetition.',
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
                      text: 'Load Starter Study Decks',
                      icon: Icons.download_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: () async {
                        await ref
                            .read(flashcardDecksProvider.notifier)
                            .seedStarterDecks();
                      },
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: 'Create Custom Deck',
                      icon: Icons.add_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: () => _showCreateDeckDialog(context, ref),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.space16),
            itemCount: decks.length + 1,
            itemBuilder: (context, idx) {
              if (idx == 0) {
                // Leitner Spaced Repetition Mastery Hero Card
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E1B4B), const Color(0xFF172554)]
                          : [const Color(0xFFEEF2FF), const Color(0xFFEFF6FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('🧠', style: TextStyle(fontSize: 20)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Leitner Box Retention Engine',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Spaced Repetition prevents memory decay over time',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // 4 Leitner Box Legend Pills
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildLeitnerPill('Box 1: Learning (1d)', const Color(0xFFEF4444)),
                          _buildLeitnerPill('Box 2: Review (3d)', const Color(0xFFF59E0B)),
                          _buildLeitnerPill('Box 3: Strong (7d)', const Color(0xFF3B82F6)),
                          _buildLeitnerPill('Box 4: Mastered (14d+)', const Color(0xFF10B981)),
                        ],
                      ),
                    ],
                  ),
                );
              }

              final deck = decks[idx - 1];
              final deckColor = _parseColor(deck.colorHex);

              return Consumer(
                builder: (context, ref, child) {
                  final masteryAsync = ref.watch(deckMasteryProvider(deck.id));
                  final mastery = masteryAsync.valueOrNull ??
                      const LeitnerDeckMastery(
                        box1Learning: 0,
                        box2Review: 0,
                        box3Consolidating: 0,
                        box4Mastered: 0,
                        totalCards: 0,
                        dueToday: 0,
                        retentionPercentage: 0,
                      );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () {
                        context.push(AppRoutes.flashcardsReview, extra: deck);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Subject Icon Box
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: deckColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.style_rounded,
                                  color: deckColor,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      deck.title,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${deck.subject} • ${deck.description}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Review Button
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: deckColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                                label: const Text(
                                  'Review',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                onPressed: () {
                                  context.push(AppRoutes.flashcardsReview, extra: deck);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),

                          // Leitner Retention Bar & Due Stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: mastery.retentionPercentage >= 70
                                            ? AppColors.success.withValues(alpha: 0.15)
                                            : AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '🧠 ${mastery.retentionPercentage}% Retained',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: mastery.retentionPercentage >= 70
                                              ? AppColors.success
                                              : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    if (mastery.box4Mastered > 0) ...[
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          '• ${mastery.box4Mastered} Mastered',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (mastery.dueToday > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '🔔 ${mastery.dueToday} Due Today',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // 4-box Segmented Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              height: 6,
                              child: Row(
                                children: [
                                  _buildBoxSegment(mastery.box1Learning, mastery.totalCards, const Color(0xFFEF4444)),
                                  _buildBoxSegment(mastery.box2Review, mastery.totalCards, const Color(0xFFF59E0B)),
                                  _buildBoxSegment(mastery.box3Consolidating, mastery.totalCards, const Color(0xFF3B82F6)),
                                  _buildBoxSegment(mastery.box4Mastered, mastery.totalCards, const Color(0xFF10B981)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'New Deck',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        onPressed: () => _showCreateDeckDialog(context, ref),
      ),
    );
  }

  Widget _buildLeitnerPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxSegment(int count, int total, Color color) {
    final flex = total > 0 && count > 0 ? count : 0;
    if (flex == 0) return const SizedBox.shrink();
    return Expanded(
      flex: flex,
      child: Container(
        color: color,
        margin: const EdgeInsets.symmetric(horizontal: 0.5),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return AppColors.primary;
    }
  }

  void _showCreateDeckDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Create Flashcard Deck',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: titleCtrl,
                  label: 'Deck Title',
                  hint: 'e.g. Organic Chemistry Reactions',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: subjectCtrl,
                  label: 'Subject',
                  hint: 'e.g. Chemistry',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: descCtrl,
                  label: 'Description',
                  hint: 'e.g. Key mechanisms and reagents',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await ref
                    .read(flashcardDecksProvider.notifier)
                    .createDeck(
                      title: titleCtrl.text.trim(),
                      subject: subjectCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text(
                'Create',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
