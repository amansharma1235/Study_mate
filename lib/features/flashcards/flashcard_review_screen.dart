import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_button.dart';
import '../../data/local/app_database.dart';
import '../../data/local/voice_study_service.dart';
import '../../data/models/flashcard_model.dart';
import '../gamification/gamification_controller.dart';
import 'flashcards_controller.dart';

class FlashcardReviewScreen extends ConsumerStatefulWidget {
  final FlashcardDeckModel deck;

  const FlashcardReviewScreen({super.key, required this.deck});

  @override
  ConsumerState<FlashcardReviewScreen> createState() =>
      _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends ConsumerState<FlashcardReviewScreen>
    with TickerProviderStateMixin {
  // Flip Animation
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFront = true;

  // Swipe Animation & Drag Physics
  late AnimationController _swipeController;
  Animation<Offset>? _swipeOffsetAnimation;
  Offset _dragOffset = Offset.zero;

  int _currentIndex = 0;
  List<FlashcardModel> _cards = [];
  bool _isLoading = true;
  int _masteredCount = 0;
  int _againCount = 0;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );

    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
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
    HapticFeedback.selectionClick();
    if (_flipController.isAnimating) return;
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (_swipeController.isAnimating || _currentIndex >= _cards.length) return;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_swipeController.isAnimating || _currentIndex >= _cards.length) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_swipeController.isAnimating || _currentIndex >= _cards.length) return;

    final velocity = details.velocity.pixelsPerSecond.dx;
    final dx = _dragOffset.dx;

    // Swipe Right (Mastered / Easy)
    if (dx > 100 || velocity > 650) {
      _animateSwipe(const Offset(550, 0), isMastered: true);
    }
    // Swipe Left (Again / Review)
    else if (dx < -100 || velocity < -650) {
      _animateSwipe(const Offset(-550, 0), isMastered: false);
    }
    // Return to Center
    else {
      _animateReturn();
    }
  }

  void _animateSwipe(Offset target, {required bool isMastered}) {
    if (isMastered) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    _swipeOffsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));

    _swipeController.forward(from: 0).then((_) {
      _applyRating(isMastered ? CardRating.easy : CardRating.again);
      _dragOffset = Offset.zero;
      _swipeController.reset();
    });
  }

  void _animateReturn() {
    _swipeOffsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.elasticOut));

    _swipeController.forward(from: 0).then((_) {
      _dragOffset = Offset.zero;
      _swipeController.reset();
    });
  }

  Future<void> _applyRating(CardRating rating) async {
    if (_currentIndex >= _cards.length) return;

    final currentCard = _cards[_currentIndex];
    final updatedCard = currentCard.review(rating);
    final db = ref.read(appDatabaseProvider);
    await db.updateFlashcard(updatedCard);
    if (!mounted) return;

    if (rating == CardRating.easy || rating == CardRating.good) {
      _masteredCount++;
      // Micro XP reward
      ref.read(gamificationControllerProvider.notifier).awardXp(
            amount: 5,
            reason: 'Flashcard Mastered 🌟',
            context: context,
          );
    } else {
      _againCount++;
    }

    // Reset flip for next card
    if (!_isFront) {
      _flipController.reset();
      _isFront = true;
    }

    setState(() {
      _showHint = false;
      _currentIndex++;
    });

    // Check completion
    if (_currentIndex >= _cards.length && mounted) {
      ref.read(gamificationControllerProvider.notifier).recordFlashcardsMastered(context);
    }
  }

  Future<void> _speakCurrentCard() async {
    if (_currentIndex >= _cards.length) return;
    final card = _cards[_currentIndex];
    final textToSpeak = _isFront
        ? 'Question: ${card.front}'
        : 'Answer: ${card.back}';
    final voiceService = ref.read(voiceStudyServiceProvider);
    await voiceService.speak(textToSpeak);
  }

  @override
  void dispose() {
    _flipController.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.deck.title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            Text(
              'Interactive 3D Study Studio',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded),
            tooltip: 'Read Aloud 🔊',
            onPressed: _speakCurrentCard,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Restart Deck',
            onPressed: () {
              setState(() {
                _currentIndex = 0;
                _masteredCount = 0;
                _againCount = 0;
                _isFront = true;
                _showHint = false;
                _flipController.reset();
              });
            },
          ),
        ],
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space20,
          vertical: AppDimensions.space12,
        ),
        child: Column(
          children: [
            // Progress Bar & Counts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$_masteredCount Mastered',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$_againCount Again',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_currentIndex + 1} / ${_cards.length}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              borderRadius: BorderRadius.circular(4),
              minHeight: 5,
            ),
            const SizedBox(height: 18),

            // 3D Physical Card Stack View
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Third Card in background
                  if (_currentIndex + 2 < _cards.length)
                    _buildBackgroundCard(
                      scale: 0.90,
                      translateY: 26,
                      opacity: 0.40,
                      isDark: isDark,
                    ),

                  // Second Card in background
                  if (_currentIndex + 1 < _cards.length)
                    _buildBackgroundCard(
                      scale: 0.95,
                      translateY: 13,
                      opacity: 0.75,
                      isDark: isDark,
                    ),

                  // Top Interactive Active Card
                  GestureDetector(
                    onTap: _flipCard,
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_flipAnimation, _swipeController]),
                      builder: (context, child) {
                        final currentOffset = _swipeController.isAnimating &&
                                _swipeOffsetAnimation != null
                            ? _swipeOffsetAnimation!.value
                            : _dragOffset;

                        final flipAngle = _flipAnimation.value * pi;
                        final isUnder = flipAngle > pi / 2;
                        final rotationZ = (currentOffset.dx / 400) * (pi / 12);

                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // 3D Perspective
                            ..translateByDouble(currentOffset.dx, currentOffset.dy, 0.0, 1.0)
                            ..rotateZ(rotationZ)
                            ..rotateY(flipAngle),
                          alignment: Alignment.center,
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.cardDark : Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: _getBorderColor(currentOffset.dx, isDark),
                                    width: currentOffset.dx.abs() > 30 ? 2.5 : 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.35 : 0.09,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
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

                              // Swipe Overlay Stamp (Mastered)
                              if (currentOffset.dx > 25)
                                Positioned(
                                  top: 30,
                                  left: 30,
                                  child: Opacity(
                                    opacity: (currentOffset.dx / 120).clamp(0.0, 1.0),
                                    child: Transform.rotate(
                                      angle: -pi / 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppColors.success,
                                            width: 2.5,
                                          ),
                                        ),
                                        child: Text(
                                          'MASTERED 🌟',
                                          style: GoogleFonts.outfit(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 20,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Swipe Overlay Stamp (Review Again)
                              if (currentOffset.dx < -25)
                                Positioned(
                                  top: 30,
                                  right: 30,
                                  child: Opacity(
                                    opacity: ((-currentOffset.dx) / 120).clamp(0.0, 1.0),
                                    child: Transform.rotate(
                                      angle: pi / 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppColors.error,
                                            width: 2.5,
                                          ),
                                        ),
                                        child: Text(
                                          'AGAIN 🔁',
                                          style: GoogleFonts.outfit(
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 20,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Bottom Action Dock
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 1. Again Button (Swipe Left)
                _buildActionCircle(
                  icon: Icons.close_rounded,
                  label: 'Again',
                  color: AppColors.error,
                  onTap: () => _animateSwipe(const Offset(-550, 0), isMastered: false),
                ),

                // 2. Flip 3D Button
                _buildActionCircle(
                  icon: Icons.flip_camera_android_rounded,
                  label: _isFront ? 'Flip 3D' : 'Back',
                  color: AppColors.primary,
                  isLarge: true,
                  onTap: _flipCard,
                ),

                // 3. Mastered Button (Swipe Right)
                _buildActionCircle(
                  icon: Icons.check_rounded,
                  label: 'Mastered',
                  color: AppColors.success,
                  onTap: () => _animateSwipe(const Offset(550, 0), isMastered: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getBorderColor(double dx, bool isDark) {
    if (dx > 30) {
      return AppColors.success;
    } else if (dx < -30) {
      return AppColors.error;
    }
    return isDark ? AppColors.borderDark : AppColors.borderLight;
  }

  Widget _buildBackgroundCard({
    required double scale,
    required double translateY,
    required double opacity,
    required bool isDark,
  }) {
    return Transform(
      transform: Matrix4.identity()
        ..translateByDouble(0.0, translateY, 0.0, 1.0)
        ..scaleByDouble(scale, scale, 1.0, 1.0),
      alignment: Alignment.center,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardFront(FlashcardModel card, bool isDark) {
    return Column(
      children: [
        // Top Card Meta Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.help_outline_rounded,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'QUESTION',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, size: 20),
              color: AppColors.primary,
              tooltip: 'Listen 🔊',
              onPressed: () {
                ref.read(voiceStudyServiceProvider).speak(card.front);
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Question Center Text
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.front,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      height: 1.35,
                    ),
                  ),
                  if (card.hint.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    if (_showHint)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '💡 Hint: ${card.hint}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.amber[200] : const Color(0xFFB45309),
                          ),
                        ),
                      )
                    else
                      TextButton.icon(
                        icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                        label: const Text('Show Hint'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.warning,
                        ),
                        onPressed: () {
                          setState(() => _showHint = true);
                        },
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Bottom Gesture Guides
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.swipe_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Tap to Flip • Swipe Left (Again) / Right (Mastered)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardBack(FlashcardModel card, bool isDark) {
    return Column(
      children: [
        // Top Back Meta Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 13, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'ANSWER / SOLUTION',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, size: 20),
              color: AppColors.success,
              tooltip: 'Listen Answer 🔊',
              onPressed: () {
                ref.read(voiceStudyServiceProvider).speak(card.back);
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Answer Center Text
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                card.back,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Interval & Repetition SM-2 stats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Next Review: +${card.intervalDays}d',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Reps: ${card.repetitionNumber}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCircle({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    final size = isLarge ? 62.0 : 50.0;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
              border: Border.all(color: color, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: isLarge ? 30 : 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionState(bool isDark) {
    final total = _cards.length;
    final accuracy = total > 0 ? ((_masteredCount / total) * 100).toInt() : 100;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.success, width: 2),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 64,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Session Completed! 🎉',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '+30 Scholar XP Awarded!',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 20),

            // Performance Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$_masteredCount',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          'Mastered',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$_againCount',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.error,
                          ),
                        ),
                        Text(
                          'To Review',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$accuracy%',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Retention',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Review Again'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      setState(() {
                        _currentIndex = 0;
                        _masteredCount = 0;
                        _againCount = 0;
                        _isFront = true;
                        _showHint = false;
                        _flipController.reset();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Done',
                    variant: AppButtonVariant.primary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCardsState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.style_outlined,
              size: 58,
              color: AppColors.textMutedLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Deck is Empty',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first flashcard or load 5 starter smart cards to test the 3D swipe studio.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('Load 5 Starter Smart Cards ⚡'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onPressed: () async {
                final starterCards = [
                  {
                    'front': 'What is the First Law of Thermodynamics?',
                    'back': 'Energy cannot be created or destroyed, only transformed: ΔU = Q - W.',
                    'hint': 'Conservation of energy principle',
                  },
                  {
                    'front': 'What is Ohm\'s Law formula?',
                    'back': 'V = I · R (Voltage equals current multiplied by resistance).',
                    'hint': 'Relates V, I, and R in electrical circuits',
                  },
                  {
                    'front': 'Explain De Morgan\'s First Law in Boolean Algebra.',
                    'back': '(A · B)\' = A\' + B\' (The complement of a product equals the sum of the complements).',
                    'hint': 'NAND to OR inversion',
                  },
                  {
                    'front': 'What is the time complexity of Binary Search?',
                    'back': 'O(log n) because the search space is halved in every iteration.',
                    'hint': 'Logarithmic division',
                  },
                  {
                    'front': 'What is Avogadro\'s number constant value?',
                    'back': '6.022 × 10²³ particles per mole.',
                    'hint': 'Particles in one mole of substance',
                  },
                ];

                for (final c in starterCards) {
                  await ref.read(flashcardDecksProvider.notifier).addCardToDeck(
                        deckId: widget.deck.id,
                        front: c['front']!,
                        back: c['back']!,
                        hint: c['hint']!,
                      );
                }
                _loadCards();
              },
            ),
          ],
        ),
      ),
    );
  }
}
