import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routing/route_names.dart';

class MainScaffoldScreen extends StatelessWidget {
  final Widget child;

  const MainScaffoldScreen({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.notes)) return 1;
    if (location.startsWith(AppRoutes.tasks)) return 2;
    if (location.startsWith(AppRoutes.more) ||
        location.startsWith(AppRoutes.timetable) ||
        location.startsWith(AppRoutes.timer) ||
        location.startsWith(AppRoutes.exams) ||
        location.startsWith(AppRoutes.quizCategories) ||
        location.startsWith(AppRoutes.percentageCalculator) ||
        location.startsWith(AppRoutes.multiSubjectCalculator) ||
        location.startsWith(AppRoutes.cgpaCalculator) ||
        location.startsWith(AppRoutes.planner) ||
        location.startsWith(AppRoutes.flashcards) ||
        location.startsWith(AppRoutes.syllabus) ||
        location.startsWith(AppRoutes.aiAssistant) ||
        location.startsWith(AppRoutes.documents) ||
        location.startsWith(AppRoutes.voiceNotes) ||
        location.startsWith(AppRoutes.habits) ||
        location.startsWith(AppRoutes.coding) ||
        location.startsWith(AppRoutes.career) ||
        location.startsWith(AppRoutes.studyGroups) ||
        location.startsWith(AppRoutes.studyTips) ||
        location.startsWith(AppRoutes.studyStatistics) ||
        location.startsWith(AppRoutes.profile)) {
      return 3;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.notes);
        break;
      case 2:
        context.go(AppRoutes.tasks);
        break;
      case 3:
        context.go(AppRoutes.more);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, 0, currentIndex, Icons.home_rounded, Icons.home_outlined, AppStrings.navHome, isDark),
                _buildNavItem(context, 1, currentIndex, Icons.article_rounded, Icons.article_outlined, AppStrings.navNotes, isDark),
                _buildNavItem(context, 2, currentIndex, Icons.check_circle_rounded, Icons.check_circle_outline_rounded, AppStrings.navTasks, isDark),
                _buildNavItem(context, 3, currentIndex, Icons.grid_view_rounded, Icons.grid_view_outlined, AppStrings.navMore, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    int currentIndex,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    bool isDark,
  ) {
    final isSelected = index == currentIndex;
    const activeColor = Color(0xFF2563EB);
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return InkWell(
      onTap: () => _onItemTapped(index, context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 16,
              height: 2.5,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
