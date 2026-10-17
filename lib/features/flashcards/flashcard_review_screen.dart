import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_button.dart';
import '../../data/local/app_database.dart';
import '../../data/models/flashcard_model.dart';
import 'flashcards_controller.dart';

class FlashcardReviewScreen extends ConsumerStatefulWidget {
  final FlashcardDeckModel deck;

  const FlashcardReviewScreen({super.key, required this.deck});

  @override
  ConsumerState<FlashcardReviewScreen> createState() =>
      _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends ConsumerState<FlashcardReviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  bool _isFront = true;
  int _currentIndex = 0;
  List<FlashcardModel> _cards = [];
  bool _isLoading = true;
  int _reviewedCount = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _loadCards();
  }

  Future<void> _loadCards() async {
    final db = ref.read(appDatabaseProvider);
    final list = await db.getFlashcards(widget.deck.id);
    if (mounted) {
      setState(() {
        _cards = list;
        _isLoading = false;
      });
    }
  }

  void _flipCard() {
    if (_animController.isAnimating) return;
    if (_isFront) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  Future<void> _rateCard(CardRating rating) async {
    final currentCard = _cards[_currentIndex];
    final updatedCard = currentCard.review(rating);
    final db = ref.read(appDatabaseProvider);
    await db.updateFlashcard(updatedCard);

    if (_isFront == false) {
      _animController.reverse();
      _isFront = true;
    }

    setState(() {
      _reviewedCount++;
      _currentIndex++;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          widget.deck.title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
          ? _buildEmptyCardsState(isDark)
          : _currentIndex >= _cards.length
          ? _buildCompletionState(isDark)
          : _buildReviewContent(isDark),
    );
  }

  Widget _buildReviewContent(bool isDark) {
    final card = _cards[_currentIndex];
    final progress = (_currentIndex + 1) / _cards.length;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.space20),
      child: Column(
        children: [
          // Progress Bar & Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${_currentIndex + 1} of ${_cards.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark
                ? AppColors.borderDark
                : AppColors.borderLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 24),

          // Flip Card Area
          Expanded(
            child: GestureDetector(
              onTap: _flipCard,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final angle = _animation.value * pi;
                  final isUnder = angle > pi / 2;

                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    alignment: Alignment.center,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.08,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: isUnder
                          ? Transform(
                              transform: Matrix4.identity()..rotateY(pi),
                              alignment: Alignment.center,
                              child: _buildCardBack(card, isDark),
                            )
                          : _buildCardFront(card, isDark),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Rating Action Buttons
          if (!_isFront) ...[
            Text(
              'How well did you know this?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildRatingButton(
                  label: 'Again',
                  subtitle: '< 1d',
                  color: AppColors.error,
                  onTap: () => _rateCard(CardRating.again),
                ),
                const SizedBox(width: 8),
                _buildRatingButton(
                  label: 'Hard',
                  subtitle: '2d',
                  color: Colors.orange,
                  onTap: () => _rateCard(CardRating.hard),
                ),
                const SizedBox(width: 8),
                _buildRatingButton(
                  label: 'Good',
                  subtitle: '5d',
                  color: AppColors.primary,
                  onTap: () => _rateCard(CardRating.good),
                ),
                const SizedBox(width: 8),
                _buildRatingButton(
                  label: 'Easy',
                  subtitle: '10d',
                  color: AppColors.success,
                  onTap: () => _rateCard(CardRating.easy),
                ),
              ],
            ),
          ] else ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.flip_rounded),
              label: const Text(
                'Tap Card to Reveal Answer',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: _flipCard,
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCardFront(FlashcardModel card, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'QUESTION / TERM',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          card.front,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            height: 1.4,
          ),
        ),
        if (card.hint.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            '💡 Hint: ${card.hint}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
          ),
        ],
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 16,
              color: AppColors.textMutedLight,
            ),
            const SizedBox(width: 6),
            Text(
              'Tap anywhere to flip',
              style: TextStyle(fontSize: 12, color: AppColors.textMutedLight),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardBack(FlashcardModel card, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'ANSWER / EXPLANATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.success,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          card.back,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            height: 1.5,
          ),
        ),
        const Spacer(),
        const Text(
          'Rate your recall below 👇',
          style: TextStyle(fontSize: 12, color: AppColors.textMutedLight),
        ),
      ],
    );
  }

  Widget _buildRatingButton({
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Session Completed! 🎉',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You reviewed $_reviewedCount flashcards in ${widget.deck.title}. Spaced repetition intervals have been recalculated according to the SuperMemo SM-2 algorithm.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            AppButton(
              text: 'Back to Decks',
              variant: AppButtonVariant.primary,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCardsState(bool isDark) {
    final frontCtrl = TextEditingController();
    final backCtrl = TextEditingController();
    final hintCtrl = TextEditingController();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.style_outlined,
              size: 54,
              color: AppColors.textMutedLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Deck is Empty',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first flashcard with front question and back answer to start reviewing.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),
            AppButton(
              text: 'Add First Card',
              icon: Icons.add_rounded,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Add Flashcard'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: frontCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Front (Question)',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: backCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Back (Answer)',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: hintCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Hint (Optional)',
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (frontCtrl.text.isEmpty || backCtrl.text.isEmpty) {
                            return;
                          }
                          await ref
                              .read(flashcardDecksProvider.notifier)
                              .addCardToDeck(
                                deckId: widget.deck.id,
                                front: frontCtrl.text.trim(),
                                back: backCtrl.text.trim(),
                                hint: hintCtrl.text.trim(),
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadCards();
                        },
                        child: const Text('Add Card'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
