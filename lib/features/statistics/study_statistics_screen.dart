import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/study_heatmap_matrix.dart';
import '../home/home_controller.dart';
import '../timer/timer_history_screen.dart';

class StudyStatisticsScreen extends ConsumerWidget {
  const StudyStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboardAsync = ref.watch(homeDashboardProvider);
    final historyAsync = ref.watch(studyHistoryProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Study Analytics',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading stats: $err')),
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Stat Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Today Focus',
                      value: DateFormatter.formatMinutesToHours(
                        data.todayStudyMinutes,
                      ),
                      icon: Icons.timer_rounded,
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Current Streak',
                      value: '${data.studyStreakDays} Days',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.warning,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Task Completion',
                      value:
                          '${(data.taskCompletionPercentage * 100).toInt()}%',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.secondary,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Daily Goal',
                      value: '${data.dailyGoalMinutes}m',
                      icon: Icons.flag_rounded,
                      color: AppColors.success,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space20),

              // Weekly Bar Chart
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Study Distribution',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Minutes focused each day from Monday to Sunday',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 180,
                          titlesData: FlTitlesData(
                            show: true,
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (v, m) => Text(
                                  '${v.toInt()}m',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight,
                                  ),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final days = [
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                    'Sun',
                                  ];
                                  final index = val.toInt() - 1;
                                  if (index >= 0 && index < days.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        days[index],
                                        style: TextStyle(
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (val) => FlLine(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                              strokeWidth: 0.8,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(7, (i) {
                            final weekday = i + 1;
                            final mins = (data.weeklyStudyMinutes[weekday] ?? 0)
                                .toDouble();
                            return BarChartGroupData(
                              x: weekday,
                              barRods: [
                                BarChartRodData(
                                  toY: mins,
                                  color: weekday == DateTime.now().weekday
                                      ? AppColors.primary
                                      : AppColors.secondary,
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space20),

              // 365-Day Study Activity Matrix (GitHub Style)
              historyAsync.when(
                loading: () => const SizedBox(),
                error: (_, _) => const SizedBox(),
                data: (sessions) {
                  final Map<DateTime, int> activityMap = {};
                  for (final s in sessions) {
                    final d = DateTime(
                      s.completedAt.year,
                      s.completedAt.month,
                      s.completedAt.day,
                    );
                    activityMap[d] =
                        (activityMap[d] ?? 0) + s.durationMinutes;
                  }
                  // Ensure today's minutes from dashboard are included
                  final today = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  );
                  activityMap[today] = (activityMap[today] ?? 0) >
                          data.todayStudyMinutes
                      ? activityMap[today]!
                      : data.todayStudyMinutes;

                  return AppCard(
                    child: StudyHeatmapMatrix(
                      activityData: activityMap,
                      weeksToShow: 18,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppDimensions.space20),

              // Subject Focus Breakdown
              historyAsync.when(
                loading: () => const SizedBox(),
                error: (_, _) => const SizedBox(),
                data: (sessions) {
                  final Map<String, int> subjectMinutes = {};
                  for (final s in sessions) {
                    subjectMinutes[s.subject] =
                        (subjectMinutes[s.subject] ?? 0) + s.durationMinutes;
                  }

                  if (subjectMinutes.isEmpty) return const SizedBox();

                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subject Focus Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...subjectMinutes.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ),
                                Text(
                                  DateFormatter.formatMinutesToHours(
                                    entry.value,
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.space12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
