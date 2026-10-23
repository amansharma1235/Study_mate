import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/routing/route_names.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/speed_dial_fab.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/task_model.dart';
import '../../data/local/preference_service.dart';
import '../../data/remote/sync_service.dart';
import '../auth/auth_controller.dart';
import '../tasks/tasks_controller.dart';
import 'home_controller.dart';

final homeActiveQuoteIndexProvider = StateProvider<int>((ref) => 0);

/// Clean, beautiful, and identical recreation of the reference StudyMate UI.
/// Features warm artistic top study background, morning mountain sunrise quote panorama,
/// deep midnight goal card with glowing gauge, pastel 2x2 quick hub, side-by-side
/// tasks & exams cards, and floating action button.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentProfileProvider);
    final dashboardAsync = ref.watch(homeDashboardProvider);
    final syncState = ref.watch(syncStateProvider);

    final bgColor = isDark ? const Color(0xFF0B101D) : const Color(0xFFF1F6FE);
    final cardBg = isDark ? const Color(0xFF151D30) : Colors.white;
    final borderColor = isDark ? const Color(0xFF222F4C) : const Color(0xFFF0F4FA);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: dashboardAsync.when(
        loading: () => _buildLoadingState(isDark),
        error: (err, _) => _buildErrorState(ref, err),
        data: (data) => RefreshIndicator(
          color: const Color(0xFF2563EB),
          onRefresh: () async {
            ref.invalidate(homeDashboardProvider);
            ref.read(tasksControllerProvider.notifier).loadTasks();
            if (user != null && user.uid.isNotEmpty) {
              await ref.read(syncStateProvider.notifier).triggerSync(user.uid);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Ambient Artistic Header (Study Desk Background + App Bar + Greeting)
                _buildArtisticHeader(context, ref, user, syncState, data, textPrimary, textMuted, isDark),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),

                      // 2. Mountain Sunrise Panoramic Quote Card
                      _buildQuotePanoramaCard(ref, data, isDark),
                      const SizedBox(height: 16),

                      // 3. Today's Study Goal Cosmic Sapphire Card
                      _buildStudyGoalCard(context, ref, data, isDark),
                      const SizedBox(height: 16),

                      // 4. 2x2 Quick Action Cards (Focus Timer, My Tasks, My Notes, Time Table)
                      _buildQuickActionCards(context, data, cardBg, borderColor, textPrimary, textMuted, isDark),
                      const SizedBox(height: 16),

                      // 5. Side-by-Side Today's Tasks & Upcoming Exams Cards
                      _buildSideBySideCards(context, ref, data, cardBg, borderColor, textPrimary, textMuted, isDark),

                      // Bottom clearance for floating action button
                      const SizedBox(height: 96),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: const SpeedDialFab(),
    );
  }

  /// 1. Top Artistic Header with Study Desk Illustration, Branding, Top Icons, and Greeting
  Widget _buildArtisticHeader(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    SyncState syncState,
    HomeDashboardData data,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    return Stack(
      children: [
        // Background illustration fading out gently to the left and bottom
        Positioned(
          top: 0,
          right: 0,
          width: 250,
          height: 230,
          child: ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.15 : 0.45),
                  Colors.white.withValues(alpha: isDark ? 0.08 : 0.25),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: Image.asset(
              'assets/images/header_study_desk.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),

        // Handwritten inspiring quote floating in the upper right
        Positioned(
          top: 104,
          right: 20,
          child: Transform.rotate(
            angle: -0.06,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.studyQuote.shortHandwritten,
                  style: GoogleFonts.caveat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 65,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Foreground Header & Greeting Content
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Navigation Row: Logo + StudyMate + 3 Frosted Action Circles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand mark & title
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.asset(
                              'assets/branding/studymate_logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  fontSize: 19.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Study',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: 'Mate',
                                    style: TextStyle(
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Learn  •  Plan  •  Grow',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Right 3 Frosted Circular Buttons: Cloud Sync + Notification + Profile Avatar
                    Row(
                      children: [
                        // Cloud Sync
                        _buildFrostedCircleButton(
                          onTap: () {
                            if (user != null && user.uid.isNotEmpty) {
                              ref.read(syncStateProvider.notifier).triggerSync(user.uid);
                            }
                          },
                          child: syncState.isSyncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF2563EB),
                                  ),
                                )
                              : const Icon(
                                  Icons.cloud_sync_rounded,
                                  size: 20,
                                  color: Color(0xFF2563EB),
                                ),
                          tooltip: syncState.isCloudConnected ? 'Cloud Synced' : 'Offline Mode',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),

                        // Notification Bell with Red Indicator Dot
                        _buildFrostedCircleButton(
                          onTap: () => context.push(AppRoutes.notificationSettings),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(
                                Icons.notifications_none_rounded,
                                size: 21,
                                color: Color(0xFF2563EB),
                              ),
                              Positioned(
                                top: -1,
                                right: -1,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          tooltip: 'Notifications',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),

                        // Profile Avatar next to Notification Bell
                        InkWell(
                          onTap: () => context.push(AppRoutes.profile),
                          borderRadius: BorderRadius.circular(20),
                          child: UserAvatar(
                            photoUrl: user?.photoUrl,
                            name: (user?.displayName?.isNotEmpty == true)
                                ? user!.displayName
                                : (data.userName.isNotEmpty ? data.userName : 'Student'),
                            size: 38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Greeting & Date Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data.greeting},',
                            style: GoogleFonts.inter(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  data.userName.isNotEmpty ? data.userName : 'Scholar',
                                  style: GoogleFonts.inter(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: const Color(0xFF2563EB),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '☀️',
                                style: TextStyle(fontSize: 22),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Keep going, your future is brighter than you think!',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: Color(0xFF475569),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${DateFormatter.formatDate(DateTime.now())}  |  ${_getDayOfWeek(DateTime.now())}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Expanded(
                      flex: 4,
                      child: SizedBox.shrink(), // Room for floating background desk note
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Helper for Frosted Circular Glass Action Buttons
  Widget _buildFrostedCircleButton({
    required VoidCallback onTap,
    required Widget child,
    required String tooltip,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.88),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0).withValues(alpha: 0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  /// 2. Daily Inspiration Mountain Sunrise Panorama Card (Interactive & Dynamic)
  Widget _buildQuotePanoramaCard(WidgetRef ref, HomeDashboardData data, bool isDark) {
    final activeIndex = ref.watch(homeActiveQuoteIndexProvider);
    final quotes = data.allQuotes.isNotEmpty ? data.allQuotes : [data.studyQuote];
    final currentQuote = quotes[activeIndex % quotes.length];

    return InkWell(
      onTap: () {
        ref.read(homeActiveQuoteIndexProvider.notifier).state =
            (activeIndex + 1) % quotes.length;
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        height: 128,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Background mountain sunrise image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/quote_mountain_sunrise.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE0E7FF), Color(0xFFFEF3C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),

              // Left translucent soft white/fog overlay for high text legibility
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.90),
                        Colors.white.withValues(alpha: 0.72),
                        Colors.white.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.50, 0.78, 1.0],
                    ),
                  ),
                ),
              ),

              // Quote Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Circular Frosted Quote Mark Badge
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '“',
                          style: TextStyle(
                            fontSize: 28,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Quote and Author Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '“${currentQuote.quote}”',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              height: 1.3,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '— ${currentQuote.author}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.touch_app_outlined,
                                size: 12,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Tap to shuffle',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Pagination Dots at bottom center
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    quotes.length.clamp(1, 5),
                    (dotIndex) {
                      final isCurrent = (activeIndex % quotes.length) % 5 == dotIndex;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: isCurrent ? 16 : 4.5,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF94A3B8).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3. Today's Study Goal Cosmic Sapphire Card
  Widget _buildStudyGoalCard(BuildContext context, WidgetRef ref, HomeDashboardData data, bool isDark) {
    final studyMinutes = data.todayStudyMinutes;
    final goalMinutes = data.dailyGoalMinutes;
    final hasGoal = goalMinutes > 0;
    final progress = hasGoal ? (studyMinutes / goalMinutes).clamp(0.0, 1.0) : 0.0;

    final String statusLine1;
    final String statusLine2;
    if (studyMinutes == 0 && !hasGoal) {
      statusLine1 = "Ready to";
      statusLine2 = "focus! 🚀";
    } else if (studyMinutes == 0) {
      statusLine1 = "Let's";
      statusLine2 = "begin! ⏱️";
    } else if (hasGoal && studyMinutes >= goalMinutes) {
      statusLine1 = "Goal";
      statusLine2 = "achieved! 🎉";
    } else {
      statusLine1 = "You're";
      statusLine2 = "doing great! ↗";
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF071A35),
            Color(0xFF0C274A),
            Color(0xFF103668),
            Color(0xFF1E3A8A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF071A35).withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background organic subtle glowing leaf/waves in bottom right
          Positioned(
            right: -10,
            bottom: -15,
            child: Opacity(
              opacity: 0.12,
              child: Icon(
                Icons.spa_rounded,
                size: 140,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column: Goal header, Completed / Target min, Progress Bar, Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Target Icon + Title + "Stay Focused" / "Set Goal" Tag
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Icon(
                              Icons.track_changes_rounded,
                              size: 13,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Today's Study Goal",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _showSetGoalDialog(context, ref, goalMinutes),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    hasGoal ? 'Stay Focused' : 'Set Goal',
                                    style: const TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF93C5FD),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.edit_rounded,
                                    size: 8,
                                    color: Color(0xFF93C5FD),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),

                      // Study minutes / Goal minutes
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$studyMinutes',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: hasGoal ? ' / $goalMinutes min' : ' / 0 min',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 7),

                      // Glowing Neon Cyan-Blue Progress Bar
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00F2FE).withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Completed & Target Stats Row
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 11, color: Colors.white70),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              'Completed\n$studyMinutes min',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.15,
                              ),
                              maxLines: 2,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Container(
                              height: 16,
                              width: 1,
                              color: Colors.white24,
                            ),
                          ),
                          const Icon(Icons.track_changes_rounded, size: 11, color: Colors.white70),
                          const SizedBox(width: 2),
                          Flexible(
                            child: InkWell(
                              onTap: () => _showSetGoalDialog(context, ref, goalMinutes),
                              child: Text(
                                hasGoal ? 'Target\n$goalMinutes min' : 'Target\n0 min',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.15,
                                ),
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Right Column: Circular Progress Ring with Leaf + Dynamic Status + Action Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Circular Progress Ring with Glowing Leaf Center
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CustomPaint(
                            painter: _CircularProgressLeafPainter(progress: progress),
                            child: Center(
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF072738),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00F2FE).withValues(alpha: 0.3),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.eco_rounded,
                                  size: 15,
                                  color: Color(0xFF2DD4BF),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),

                        // Dynamic Status Text
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              statusLine1,
                              style: GoogleFonts.inter(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              statusLine2,
                              style: GoogleFonts.inter(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Start / Continue Focus Capsule Button
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => context.push(AppRoutes.timer),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.play_arrow_rounded,
                                size: 14,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                studyMinutes > 0 ? 'Continue Focus' : 'Start Focus',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Interactive Modal Bottom Sheet to configure daily study target
  void _showSetGoalDialog(BuildContext context, WidgetRef ref, int currentGoal) {
    int selected = currentGoal > 0 ? currentGoal : 60;
    final controller = TextEditingController(text: currentGoal > 0 ? '$currentGoal' : '60');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.track_changes_rounded, color: Color(0xFF2563EB), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Set Daily Study Goal',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose how many minutes you want to study each day:',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [30, 45, 60, 90, 120, 180].map((mins) {
                      final isSelected = selected == mins;
                      return ChoiceChip(
                        label: Text('$mins min'),
                        selected: isSelected,
                        selectedColor: const Color(0xFF2563EB),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                        ),
                        onSelected: (val) {
                          if (val) {
                            setModalState(() {
                              selected = mins;
                              controller.text = '$mins';
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Custom Target (Minutes)',
                      suffixText: 'min',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        setModalState(() => selected = parsed);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final finalGoal = int.tryParse(controller.text.trim()) ?? selected;
                        if (finalGoal <= 0) return;
                        final user = ref.read(currentProfileProvider);
                        await ref.read(preferenceServiceProvider).setDailyGoalMinutes(finalGoal, user?.uid);
                        await ref.read(authControllerProvider.notifier).updateProfile(
                          displayName: user?.displayName ?? '',
                          photoUrl: user?.photoUrl,
                          dailyGoalMinutes: finalGoal,
                        );
                        ref.invalidate(homeDashboardProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Daily study goal set to $finalGoal minutes!'),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Save Study Goal',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 4. 2x2 Quick Action Cards: Focus Timer, My Tasks, My Notes, Time Table
  Widget _buildQuickActionCards(
    BuildContext context,
    HomeDashboardData data,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    return Column(
      children: [
        // Row 1: Focus Timer & My Tasks
        Row(
          children: [
            Expanded(
              child: _buildSingleQuickCard(
                icon: Icons.timer_outlined,
                iconColor: const Color(0xFFF43F5E),
                squircleBg: const Color(0xFFFFF1F2),
                title: 'Focus Timer',
                subtitle: 'Stay focused & productive',
                accentColor: const Color(0xFFF43F5E),
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textMuted: textMuted,
                onTap: () => context.push(AppRoutes.timer),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSingleQuickCard(
                icon: Icons.done_all_rounded,
                iconColor: const Color(0xFF2563EB),
                squircleBg: const Color(0xFFEFF6FF),
                title: 'My Tasks',
                subtitle: 'Plan & complete',
                accentColor: const Color(0xFF2563EB),
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textMuted: textMuted,
                onTap: () => context.go(AppRoutes.tasks),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: My Notes & Time Table
        Row(
          children: [
            Expanded(
              child: _buildSingleQuickCard(
                icon: Icons.article_rounded,
                iconColor: const Color(0xFF10B981),
                squircleBg: const Color(0xFFECFDF5),
                title: 'My Notes',
                subtitle: 'Capture your thoughts',
                accentColor: const Color(0xFF10B981),
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textMuted: textMuted,
                onTap: () => context.go(AppRoutes.notes),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSingleQuickCard(
                icon: Icons.calendar_today_rounded,
                iconColor: const Color(0xFFF59E0B),
                squircleBg: const Color(0xFFFFFBEB),
                title: 'Time Table',
                subtitle: 'Stay on track',
                accentColor: const Color(0xFFF59E0B),
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textMuted: textMuted,
                onTap: () => context.push(AppRoutes.timetable),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Single Quick Action Card with subtle pastel watercolor corner wave
  Widget _buildSingleQuickCard({
    required IconData icon,
    required Color iconColor,
    required Color squircleBg,
    required String title,
    required String subtitle,
    required Color accentColor,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textMuted,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle pastel gradient wash in bottom right corner
              Positioned(
                right: -10,
                bottom: -10,
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Row(
                children: [
                  // Squircle Pastel Icon
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: squircleBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(icon, color: iconColor, size: 17),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 2),

                  // Trailing Small Arrow Chevron
                  Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      color: squircleBg.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 13,
                        color: iconColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 5. Side-by-Side Today's Tasks & Upcoming Exams Cards
  Widget _buildSideBySideCards(
    BuildContext context,
    WidgetRef ref,
    HomeDashboardData data,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    final pendingTasks = data.todayTaskList.where((t) => !t.isCompleted).toList();
    final upcomingExams = data.upcomingExams.where((e) => !e.isCompleted && !e.isPast).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Card: Today's Tasks
        Expanded(
          child: _buildTasksCard(context, ref, pendingTasks, cardBg, borderColor, textPrimary, textMuted, isDark),
        ),
        const SizedBox(width: 12),

        // Right Card: Upcoming Exams
        Expanded(
          child: _buildExamsCard(context, upcomingExams, cardBg, borderColor, textPrimary, textMuted, isDark),
        ),
      ],
    );
  }

  /// Today's Tasks Card
  Widget _buildTasksCard(
    BuildContext context,
    WidgetRef ref,
    List<TaskModel> pendingTasks,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Bottom-left watercolor floral accent
          Positioned(
            left: -8,
            bottom: -8,
            child: Opacity(
              opacity: 0.15,
              child: Icon(
                Icons.eco_rounded,
                size: 60,
                color: const Color(0xFF0284C7),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Checklist icon + Today's Tasks + View All ➔
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.checklist_rounded,
                          color: Color(0xFF2563EB),
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Today's Tasks",
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => context.go(AppRoutes.tasks),
                    child: Text(
                      'View All ➔',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Body: Pending task or clean Empty State
              if (pendingTasks.isNotEmpty) ...[
                InkWell(
                  onTap: () => context.push(AppRoutes.editTask, extra: pendingTasks.first),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await ref.read(tasksControllerProvider.notifier).toggleTask(pendingTasks.first);
                          ref.invalidate(homeDashboardProvider);
                        },
                        child: const Icon(
                          Icons.radio_button_unchecked_rounded,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pendingTasks.first.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ] else ...[
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF38BDF8),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF38BDF8),
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'No pending tasks for today',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],

              // Bottom Button: + Add Task
              Center(
                child: Material(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.createTask),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      child: Text(
                        '+ Add Task',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ],
      ),
    );
  }

  /// Upcoming Exams Card
  Widget _buildExamsCard(
    BuildContext context,
    List<ExamModel> upcomingExams,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textMuted,
    bool isDark,
  ) {
    final nearest = upcomingExams.isNotEmpty ? upcomingExams.first : null;

    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Bottom-right watercolor graduation cap accent
          Positioned(
            right: -8,
            bottom: -8,
            child: Opacity(
              opacity: 0.15,
              child: Icon(
                Icons.school_rounded,
                size: 60,
                color: const Color(0xFF8B5CF6),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Calendar icon + Upcoming Exams + View All ➔
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.event_note_rounded,
                            color: Color(0xFF8B5CF6),
                            size: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Upcoming Exams',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => context.push(AppRoutes.exams),
                    child: Text(
                      'View All ➔',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Body: Nearest Exam or clean Empty State
              if (nearest != null) ...[
                InkWell(
                  onTap: () => context.push(AppRoutes.exams),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nearest.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.formatDate(nearest.examDate),
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ] else ...[
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Color(0xFF8B5CF6),
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'No upcoming exams',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],

              // Bottom Button: + Add Exam
              Center(
                child: Material(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.addExam),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      child: Text(
                        '+ Add Exam',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper for Day of Week string
  String _getDayOfWeek(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  Widget _buildLoadingState(bool isDark) {
    return const SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            LoadingSkeleton(width: double.infinity, height: 60),
            SizedBox(height: 16),
            LoadingSkeleton(width: double.infinity, height: 120),
            SizedBox(height: 16),
            LoadingSkeleton(width: double.infinity, height: 160),
            SizedBox(height: 16),
            LoadingSkeleton(width: double.infinity, height: 140),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 44, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              'Could not load dashboard: $err',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(homeDashboardProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Painter for Glowing Neon Circular Progress Gauge
class _CircularProgressLeafPainter extends CustomPainter {
  final double progress;

  _CircularProgressLeafPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Track Paint
    final trackPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.6)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, trackPaint);

    // Glowing Neon Cyan Arc
    final arcPaint = Paint()
      ..color = const Color(0xFF00F2FE)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressLeafPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
