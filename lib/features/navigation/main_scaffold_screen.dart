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
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (idx) => _onItemTapped(idx, context),
          backgroundColor: isDark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDark
              ? AppColors.textMutedDark
              : AppColors.textSecondaryLight,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: AppStrings.navHome,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description_rounded),
              label: AppStrings.navNotes,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline_rounded),
              activeIcon: Icon(Icons.check_circle_rounded),
              label: AppStrings.navTasks,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              activeIcon: Icon(Icons.grid_view_sharp),
              label: AppStrings.navMore,
            ),
          ],
        ),
      ),
    );
  }
}
