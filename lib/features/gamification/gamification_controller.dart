import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/app_haptics.dart';
import '../../data/local/preference_service.dart';

class ScholarRank {
  final int level;
  final String title;
  final String badgeEmoji;
  final int minXp;
  final int maxXp;
  final Color primaryBadgeColor;

  const ScholarRank({
    required this.level,
    required this.title,
    required this.badgeEmoji,
    required this.minXp,
    required this.maxXp,
    required this.primaryBadgeColor,
  });
}

const List<ScholarRank> kScholarRanks = [
  ScholarRank(
    level: 1,
    title: 'Novice Scholar',
    badgeEmoji: '🥉',
    minXp: 0,
    maxXp: 150,
    primaryBadgeColor: Color(0xFFCD7F32), // Bronze
  ),
  ScholarRank(
    level: 2,
    title: 'Diligent Learner',
    badgeEmoji: '📚',
    minXp: 150,
    maxXp: 450,
    primaryBadgeColor: Color(0xFF38BDF8), // Sky Blue
  ),
  ScholarRank(
    level: 3,
    title: 'Deep Thinker',
    badgeEmoji: '🧠',
    minXp: 450,
    maxXp: 900,
    primaryBadgeColor: Color(0xFF818CF8), // Indigo
  ),
  ScholarRank(
    level: 4,
    title: 'Focus Master',
    badgeEmoji: '🥇',
    minXp: 900,
    maxXp: 1600,
    primaryBadgeColor: Color(0xFFF59E0B), // Gold
  ),
  ScholarRank(
    level: 5,
    title: 'Academic Champion',
    badgeEmoji: '🏆',
    minXp: 1600,
    maxXp: 2600,
    primaryBadgeColor: Color(0xFF10B981), // Emerald
  ),
  ScholarRank(
    level: 6,
    title: 'Exam Slayer',
    badgeEmoji: '👑',
    minXp: 2600,
    maxXp: 5000,
    primaryBadgeColor: Color(0xFFEC4899), // Master Rose
  ),
];

class GamificationState {
  final int totalXp;
  final ScholarRank currentRank;
  final double levelProgress;
  final int xpNeededForNext;
  final int completedTasks;
  final int completedPomodoro;

  const GamificationState({
    required this.totalXp,
    required this.currentRank,
    required this.levelProgress,
    required this.xpNeededForNext,
    required this.completedTasks,
    required this.completedPomodoro,
  });

  ScholarRank? get nextRank {
    final nextLevel = currentRank.level + 1;
    final found = kScholarRanks.where((r) => r.level == nextLevel);
    return found.isNotEmpty ? found.first : null;
  }
}

final gamificationControllerProvider =
    StateNotifierProvider<GamificationController, GamificationState>((ref) {
  final prefs = ref.watch(preferenceServiceProvider);
  return GamificationController(prefs);
});

class GamificationController extends StateNotifier<GamificationState> {
  final PreferenceService _prefs;

  GamificationController(this._prefs)
      : super(_computeState(
          _prefs.getUserXp(),
          _prefs.getCompletedTasksCount(),
          _prefs.getCompletedPomodoroCount(),
        ));

  static GamificationState _computeState(
    int totalXp,
    int tasksCount,
    int pomodoroCount,
  ) {
    // Find matching rank
    ScholarRank activeRank = kScholarRanks.first;
    for (final rank in kScholarRanks) {
      if (totalXp >= rank.minXp) {
        activeRank = rank;
      }
    }

    final span = math.max(1, activeRank.maxXp - activeRank.minXp);
    final inLevelXp = (totalXp - activeRank.minXp).clamp(0, span);
    final progress = (inLevelXp / span).clamp(0.0, 1.0);
    final xpNeeded = math.max(0, activeRank.maxXp - totalXp);

    return GamificationState(
      totalXp: totalXp,
      currentRank: activeRank,
      levelProgress: progress,
      xpNeededForNext: xpNeeded,
      completedTasks: tasksCount,
      completedPomodoro: pomodoroCount,
    );
  }

  Future<bool> awardXp({
    required int amount,
    required String reason,
    BuildContext? context,
  }) async {
    final prevRank = state.currentRank;
    final newXp = state.totalXp + amount;
    await _prefs.setUserXp(newXp);

    final newState = _computeState(
      newXp,
      state.completedTasks,
      state.completedPomodoro,
    );
    state = newState;

    final isLevelUp = newState.currentRank.level > prevRank.level;

    if (context != null && context.mounted) {
      if (isLevelUp) {
        AppHaptics.celebration();
        showLevelUpDialog(context, newState.currentRank);
      } else {
        AppHaptics.light();
        showXpSnackBar(context, amount, reason);
      }
    }

    return isLevelUp;
  }

  Future<void> recordTaskCompleted([BuildContext? context]) async {
    await _prefs.incrementCompletedTasksCount();
    if (context != null && !context.mounted) return;
    await awardXp(
      amount: 20,
      reason: 'Task Completed',
      context: context,
    );
  }

  Future<void> recordPomodoroCompleted([BuildContext? context]) async {
    await _prefs.incrementCompletedPomodoroCount();
    if (context != null && !context.mounted) return;
    await awardXp(
      amount: 50,
      reason: 'Focus Session Finished',
      context: context,
    );
  }

  Future<void> recordFlashcardsMastered([BuildContext? context]) async {
    if (context != null && !context.mounted) return;
    await awardXp(
      amount: 30,
      reason: 'Flashcards Reviewed',
      context: context,
    );
  }

  static void showXpSnackBar(BuildContext context, int xp, String reason) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E2436),
        elevation: 8,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
        ),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF38BDF8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '+$xp XP Earned! ⚡',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    reason,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showLevelUpDialog(BuildContext context, ScholarRank newRank) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF131826),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: AppColors.brandDualGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  newRank.badgeEmoji,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'LEVEL UP! 🎉',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Rank ${newRank.level}: ${newRank.title}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Outstanding dedication! You unlocked higher scholar tier privileges with consistent focus.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12.5,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Keep Crushing It 🚀',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
