import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../utils/app_haptics.dart';

/// GitHub-style Study Activity Heatmap Matrix
/// Shows study consistency across past weeks with interactive inspection
class StudyHeatmapMatrix extends StatefulWidget {
  final Map<DateTime, int> activityData;
  final int weeksToShow;
  final bool showHeader;

  const StudyHeatmapMatrix({
    super.key,
    required this.activityData,
    this.weeksToShow = 18,
    this.showHeader = true,
  });

  @override
  State<StudyHeatmapMatrix> createState() => _StudyHeatmapMatrixState();
}

class _StudyHeatmapMatrixState extends State<StudyHeatmapMatrix> {
  DateTime? _selectedDate;
  int? _selectedMinutes;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate grid start date: Monday of (weeksToShow - 1) weeks ago
    final currentWeekday = today.weekday; // 1 = Mon, 7 = Sun
    final currentWeekMonday =
        today.subtract(Duration(days: currentWeekday - 1));
    final startDate = currentWeekMonday
        .subtract(Duration(days: (widget.weeksToShow - 1) * 7));

    // Stats calculations
    int totalActiveDays = 0;
    int totalMinutes = 0;
    widget.activityData.forEach((date, mins) {
      if (mins > 0) {
        totalActiveDays++;
        totalMinutes += mins;
      }
    });

    final totalHours = (totalMinutes / 60).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Study Activity Matrix',
                    style: GoogleFonts.outfit(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$totalActiveDays Active Days',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

        // Selected Date Floating Tooltip
        if (_selectedDate != null)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.touch_app_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  '${DateFormat('EEEE, MMM d').format(_selectedDate!)}: ',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  _selectedMinutes != null && _selectedMinutes! > 0
                      ? '$_selectedMinutes mins studied 🔥'
                      : 'No study recorded',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _selectedMinutes != null && _selectedMinutes! > 0
                        ? const Color(0xFF10B981)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

        // Scrollable Matrix Grid
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day of week labels (M, W, F)
              Padding(
                padding: const EdgeInsets.only(right: 6, top: 1),
                child: Column(
                  children: [
                    _buildDayLabel('M', isDark),
                    const SizedBox(height: 14),
                    _buildDayLabel('W', isDark),
                    const SizedBox(height: 14),
                    _buildDayLabel('F', isDark),
                  ],
                ),
              ),

              // Columns of weeks
              for (int w = 0; w < widget.weeksToShow; w++)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    children: [
                      for (int dayIndex = 0; dayIndex < 7; dayIndex++)
                        _buildDayCell(
                          startDate.add(Duration(days: (w * 7) + dayIndex)),
                          today,
                          isDark,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Bottom Legend and Stats Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total: $totalHours hrs logged',
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            Row(
              children: [
                Text(
                  'Less ',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                _buildLegendBox(
                  isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
                _buildLegendBox(const Color(0xFF10B981).withValues(alpha: 0.3)),
                _buildLegendBox(const Color(0xFF10B981).withValues(alpha: 0.6)),
                _buildLegendBox(const Color(0xFF10B981)),
                _buildLegendBox(const Color(0xFF047857)),
                Text(
                  ' More',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayLabel(String text, bool isDark) {
    return SizedBox(
      height: 13,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
      ),
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

  Widget _buildDayCell(DateTime cellDate, DateTime today, bool isDark) {
    final isFuture = cellDate.isAfter(today);
    final isToday = cellDate.year == today.year &&
        cellDate.month == today.month &&
        cellDate.day == today.day;

    // Lookup minutes
    final normDate = DateTime(cellDate.year, cellDate.month, cellDate.day);
    final minutes = widget.activityData[normDate] ?? 0;

    Color cellColor;
    if (isFuture) {
      cellColor = isDark
          ? const Color(0xFF0F172A).withValues(alpha: 0.3)
          : const Color(0xFFF8FAFC);
    } else if (minutes == 0) {
      cellColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    } else if (minutes <= 25) {
      cellColor = const Color(0xFF10B981).withValues(alpha: 0.35);
    } else if (minutes <= 60) {
      cellColor = const Color(0xFF10B981).withValues(alpha: 0.65);
    } else if (minutes <= 120) {
      cellColor = const Color(0xFF10B981);
    } else {
      cellColor = const Color(0xFF047857);
    }

    final isSelected = _selectedDate != null &&
        _selectedDate!.year == cellDate.year &&
        _selectedDate!.month == cellDate.month &&
        _selectedDate!.day == cellDate.day;

    return GestureDetector(
      onTap: () {
        if (isFuture) return;
        AppHaptics.selection();
        setState(() {
          _selectedDate = normDate;
          _selectedMinutes = minutes;
        });
      },
      child: Container(
        width: 13,
        height: 13,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(3),
          border: isSelected
              ? Border.all(color: Colors.amber, width: 1.8)
              : isToday
                  ? Border.all(
                      color: AppColors.primary,
                      width: 1.4,
                    )
                  : null,
        ),
      ),
    );
  }
}
