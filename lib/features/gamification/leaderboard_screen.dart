import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../auth/auth_controller.dart';
import 'gamification_controller.dart';

class LeaderboardEntry {
  final int rank;
  final String name;
  final String title;
  final String avatarUrl;
  final String emojiAvatar;
  final double studyHours;
  final int streakDays;
  final int xp;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.title,
    this.avatarUrl = '',
    required this.emojiAvatar,
    required this.studyHours,
    required this.streakDays,
    required this.xp,
    this.isCurrentUser = false,
  });
}

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<LeaderboardEntry> _getLeaderboardList(
    String currentUserName,
    int userXp,
    int userStreak,
    int userCompletedPomodoros,
  ) {
    final userStudyHours = (userCompletedPomodoros * 25) / 60.0;

    final mockLeaderboard = <LeaderboardEntry>[
      LeaderboardEntry(
        rank: 1,
        name: 'Aarav Sharma',
        title: '👑 Grandmaster',
        emojiAvatar: '🦁',
        studyHours: 38.5,
        streakDays: 42,
        xp: 4850,
      ),
      LeaderboardEntry(
        rank: 2,
        name: 'Priya Patel',
        title: '💎 Diamond',
        emojiAvatar: '🦊',
        studyHours: 32.0,
        streakDays: 28,
        xp: 3920,
      ),
      LeaderboardEntry(
        rank: 3,
        name: 'Rohan Mehra',
        title: '🥇 Gold Elite',
        emojiAvatar: '🦉',
        studyHours: 27.5,
        streakDays: 21,
        xp: 3100,
      ),
      LeaderboardEntry(
        rank: 4,
        name: currentUserName.isNotEmpty ? currentUserName : 'You (Scholar)',
        title: '⭐ Active Scholar',
        emojiAvatar: '🚀',
        studyHours: userStudyHours > 0 ? userStudyHours : 14.5,
        streakDays: userStreak > 0 ? userStreak : 7,
        xp: userXp > 0 ? userXp : 1850,
        isCurrentUser: true,
      ),
      LeaderboardEntry(
        rank: 5,
        name: 'Ananya Gupta',
        title: '🥈 Silver Scholar',
        emojiAvatar: '🐼',
        studyHours: 12.8,
        streakDays: 14,
        xp: 1620,
      ),
      LeaderboardEntry(
        rank: 6,
        name: 'Vikram Joshi',
        title: '🥈 Silver Scholar',
        emojiAvatar: '🐯',
        studyHours: 10.5,
        streakDays: 9,
        xp: 1340,
      ),
      LeaderboardEntry(
        rank: 7,
        name: 'Sneha Reddy',
        title: '🥉 Bronze Scholar',
        emojiAvatar: '🐨',
        studyHours: 8.2,
        streakDays: 5,
        xp: 980,
      ),
      LeaderboardEntry(
        rank: 8,
        name: 'Karan Malhotra',
        title: '🥉 Bronze Scholar',
        emojiAvatar: '🦄',
        studyHours: 6.5,
        streakDays: 4,
        xp: 750,
      ),
    ];

    return mockLeaderboard;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gamification = ref.watch(gamificationControllerProvider);
    final userProfile = ref.watch(currentProfileProvider);
    final currentUserName = userProfile?.displayName ?? 'You';
    final userStreak = (gamification.completedTasks > 0
        ? (gamification.completedTasks ~/ 2).clamp(1, 45)
        : 3);

    final list = _getLeaderboardList(
      currentUserName,
      gamification.totalXp,
      userStreak,
      gamification.completedPomodoro,
    );

    final top1 = list[0];
    final top2 = list[1];
    final top3 = list[2];
    final remaining = list.sublist(3);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Weekly Focus Arena 🏆',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.park_rounded, color: AppColors.success),
            tooltip: 'Study Garden',
            onPressed: () => context.push(AppRoutes.studyGarden),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'This Week 📅'),
            Tab(text: 'All Time 🌐'),
            Tab(text: 'Streaks 🔥'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          children: [
            // Top Podium
            _buildPodium(top1, top2, top3, isDark),
            const SizedBox(height: 20),

            // Motivation Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1B4B), const Color(0xFF2E1065)]
                      : [const Color(0xFFEEF2FF), const Color(0xFFFAF5FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Text('👑', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sunday Arena Reset in 2 Days',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF312E81),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Top 3 scholars unlock the Golden Bodhi seed & +500 XP bonus!',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Remaining Ranks List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: remaining.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = remaining[index];
                return _buildRankRow(entry, isDark);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium(
    LeaderboardEntry top1,
    LeaderboardEntry top2,
    LeaderboardEntry top3,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place Silver
          _buildPodiumColumn(
            entry: top2,
            rankText: '2',
            pedestalHeight: 95,
            pedestalColor: const Color(0xFF94A3B8),
            crownEmoji: '🥈',
            isDark: isDark,
          ),
          // 1st Place Gold (Elevated center)
          _buildPodiumColumn(
            entry: top1,
            rankText: '1',
            pedestalHeight: 130,
            pedestalColor: const Color(0xFFF59E0B),
            crownEmoji: '👑',
            isFirst: true,
            isDark: isDark,
          ),
          // 3rd Place Bronze
          _buildPodiumColumn(
            entry: top3,
            rankText: '3',
            pedestalHeight: 80,
            pedestalColor: const Color(0xFFD97706),
            crownEmoji: '🥉',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn({
    required LeaderboardEntry entry,
    required String rankText,
    required double pedestalHeight,
    required Color pedestalColor,
    required String crownEmoji,
    bool isFirst = false,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(crownEmoji, style: TextStyle(fontSize: isFirst ? 28 : 22)),
        const SizedBox(height: 2),
        // Avatar circle
        Container(
          width: isFirst ? 60 : 50,
          height: isFirst ? 60 : 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pedestalColor.withValues(alpha: 0.2),
            border: Border.all(color: pedestalColor, width: isFirst ? 2.5 : 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            entry.emojiAvatar,
            style: TextStyle(fontSize: isFirst ? 30 : 24),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 80,
          child: Text(
            entry.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Text(
          '${entry.studyHours.toStringAsFixed(1)}h',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: pedestalColor,
          ),
        ),
        const SizedBox(height: 8),
        // Pedestal
        Container(
          width: 78,
          height: pedestalHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                pedestalColor.withValues(alpha: 0.9),
                pedestalColor.withValues(alpha: 0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                rankText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                ),
              ),
              Text(
                '${entry.xp} XP',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankRow(LeaderboardEntry entry, bool isDark) {
    final isMe = entry.isCurrentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
            : (isDark ? AppColors.surfaceDark : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? AppColors.primary
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank number
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: isMe ? AppColors.primary : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : (isDark ? const Color(0xFF2A2E44) : const Color(0xFFE2E8F0)),
            ),
            alignment: Alignment.center,
            child: Text(entry.emojiAvatar, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          // Name and title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isMe ? AppColors.primary : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.title} • 🔥 ${entry.streakDays}d streak',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          // Hours & XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.studyHours.toStringAsFixed(1)}h',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                '${entry.xp} XP',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
