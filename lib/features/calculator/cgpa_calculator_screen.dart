import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';

class CourseGradeItem {
  String name;
  double credits;
  double gradePoint;

  CourseGradeItem({
    required this.name,
    this.credits = 3.0,
    this.gradePoint = 8.0,
  });
}

class CgpaCalculatorScreen extends StatefulWidget {
  const CgpaCalculatorScreen({super.key});

  @override
  State<CgpaCalculatorScreen> createState() => _CgpaCalculatorScreenState();
}

class _CgpaCalculatorScreenState extends State<CgpaCalculatorScreen> {
  String _gradingScale = '10-Point Scale'; // or '4.0 Scale'
  final List<CourseGradeItem> _courses = [
    CourseGradeItem(
      name: '',
      credits: 4,
      gradePoint: 8,
    ),
    CourseGradeItem(
      name: '',
      credits: 3,
      gradePoint: 8,
    ),
  ];

  double get _totalCredits => _courses.fold(0, (sum, c) => sum + c.credits);

  double get _calculatedSgpa {
    final totalCred = _totalCredits;
    if (totalCred == 0) return 0.0;
    final weightedPoints = _courses.fold(
      0.0,
      (sum, c) => sum + (c.credits * c.gradePoint),
    );
    return weightedPoints / totalCred;
  }

  double get _approxPercentage {
    final sgpa = _calculatedSgpa;
    if (_gradingScale == '10-Point Scale') {
      // Standard AICTE / UGC formula: (CGPA - 0.75) * 10 or CGPA * 9.5
      return (sgpa * 9.5).clamp(0, 100);
    } else {
      // 4.0 Scale to percentage: (CGPA / 4) * 100
      return ((sgpa / 4.0) * 100).clamp(0, 100);
    }
  }

  String get _letterGrade {
    final pct = _approxPercentage;
    if (pct >= 90) return 'O (Outstanding)';
    if (pct >= 80) return 'A+ (Excellent)';
    if (pct >= 70) return 'A (Very Good)';
    if (pct >= 60) return 'B+ (Good)';
    if (pct >= 50) return 'B (Above Average)';
    if (pct >= 40) return 'C (Pass)';
    return 'F (Fail)';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sgpa = _calculatedSgpa;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'CGPA & SGPA Calculator',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Formula & Methodology',
            onPressed: () => _showFormulaDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          children: [
            // Result Highlight Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calculated SGPA / CGPA',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Based on $_totalCredits Total Credits',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          sgpa.toStringAsFixed(2),
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric(
                        'Equivalent Marks',
                        '${_approxPercentage.toStringAsFixed(1)}%',
                        AppColors.secondary,
                      ),
                      _buildMetric(
                        'Standard Grade',
                        _letterGrade,
                        AppColors.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Scale Toggle
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: '10-Point Scale',
                        label: Text('10-Point Scale'),
                      ),
                      ButtonSegment(
                        value: '4.0 Scale',
                        label: Text('4.0 Scale'),
                      ),
                    ],
                    selected: {_gradingScale},
                    onSelectionChanged: (set) {
                      setState(() {
                        _gradingScale = set.first;
                        for (final c in _courses) {
                          c.gradePoint = _gradingScale == '10-Point Scale'
                              ? 8.0
                              : 3.5;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Course Rows Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Semester Courses & Credits',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Course'),
                  onPressed: () {
                    setState(() {
                      _courses.add(
                        CourseGradeItem(
                          name: 'New Subject ${_courses.length + 1}',
                          credits: 3,
                          gradePoint: _gradingScale == '10-Point Scale'
                              ? 8.0
                              : 3.0,
                        ),
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Course List
            ..._courses.asMap().entries.map((entry) {
              final idx = entry.key;
              final course = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Row 1: Course Name + Delete
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: course.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Course / Subject Name',
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                              ),
                              onChanged: (v) => course.name = v,
                            ),
                          ),
                          if (_courses.length > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.error,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() => _courses.removeAt(idx));
                              },
                            ),
                        ],
                      ),
                      const Divider(height: 16),

                      // Row 2: Credits & Grade Selectors
                      Row(
                        children: [
                          // Credits Dropdown
                          Expanded(
                            child: DropdownButtonFormField<double>(
                              initialValue: course.credits,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Credits',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                              ),
                              items: [1.0, 2.0, 3.0, 4.0, 5.0]
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text('${c.toInt()} Credits'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => course.credits = v);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Grade Point Dropdown
                          Expanded(
                            child: DropdownButtonFormField<double>(
                              initialValue: course.gradePoint,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Grade',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                              ),
                              items:
                                  (_gradingScale == '10-Point Scale'
                                          ? [
                                              10.0,
                                              9.0,
                                              8.5,
                                              8.0,
                                              7.5,
                                              7.0,
                                              6.0,
                                              5.0,
                                              4.0,
                                            ]
                                          : [
                                              4.0,
                                              3.7,
                                              3.3,
                                              3.0,
                                              2.7,
                                              2.3,
                                              2.0,
                                              1.0,
                                            ])
                                      .map(
                                        (g) => DropdownMenuItem(
                                          value: g,
                                          child: Text('Grade $g'),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => course.gradePoint = v);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),
            AppButton(
              width: double.infinity,
              text: 'Reset All Courses',
              variant: AppButtonVariant.outline,
              onPressed: () {
                setState(() {
                  _courses.clear();
                  _courses.add(
                    CourseGradeItem(
                      name: 'Subject 1',
                      credits: 4,
                      gradePoint: 8,
                    ),
                  );
                  _courses.add(
                    CourseGradeItem(
                      name: 'Subject 2',
                      credits: 3,
                      gradePoint: 8,
                    ),
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
        ),
      ],
    );
  }

  void _showFormulaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Grading Methodology'),
        content: const Text(
          '1. SGPA Formula:\nSGPA = Σ (Course Credits × Grade Points) / Σ (Total Credits)\n\n2. Percentage Conversion:\n• 10-Point Scale (AICTE standard): Percentage = SGPA × 9.5\n• 4.0 Scale: Percentage = (CGPA / 4.0) × 100\n\nAll calculations run in real-time according to official university grade point conventions.',
          style: TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
