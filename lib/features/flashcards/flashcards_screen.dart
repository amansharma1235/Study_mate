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
            itemCount: decks.length,
            itemBuilder: (context, idx) {
              final deck = decks[idx];
              final deckColor = _parseColor(deck.colorHex);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  onTap: () {
                    context.push(AppRoutes.flashcardsReview, extra: deck);
                  },
                  child: Row(
                    children: [
                      // Subject Icon Box
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: deckColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.style_rounded,
                          color: deckColor,
                          size: 28,
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
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${deck.subject} • ${deck.description}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
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
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text(
                          'Review',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () {
                          context.push(AppRoutes.flashcardsReview, extra: deck);
                        },
                      ),
                    ],
                  ),
                ),
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
          content: Column(
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
