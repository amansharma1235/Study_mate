import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../data/models/calculator_model.dart';
import 'calculator_controller.dart';

class MultiSubjectCalculatorScreen extends ConsumerStatefulWidget {
  const MultiSubjectCalculatorScreen({super.key});

  @override
  ConsumerState<MultiSubjectCalculatorScreen> createState() =>
      _MultiSubjectCalculatorScreenState();
}

class _MultiSubjectCalculatorScreenState
    extends ConsumerState<MultiSubjectCalculatorScreen> {
  MultiSubjectCalculationResult? _result;

  void _calculate() {
    final notifier = ref.read(multiSubjectCalculatorProvider.notifier);
    setState(() {
      _result = notifier.calculateTotal();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjects = ref.watch(multiSubjectCalculatorProvider);
    final notifier = ref.read(multiSubjectCalculatorProvider.notifier);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Multi-Subject Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Subject',
            onPressed: () {
              notifier.addSubject(name: 'Subject ${subjects.length + 1}');
              setState(() => _result = null);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter Marks for Each Subject',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),

            // Subject Marks List
            ...List.generate(subjects.length, (idx) {
              final sub = subjects[idx];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: sub.subjectName,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Subject Name',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (val) {
                                notifier.updateSubject(
                                  idx,
                                  sub.copyWith(subjectName: val),
                                );
                              },
                            ),
                          ),
                          if (subjects.length > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: AppColors.error,
                              ),
                              onPressed: () {
                                notifier.removeSubject(idx);
                                setState(() => _result = null);
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: sub.obtainedMarks.toString(),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Marks Obtained',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (val) {
                                final n = double.tryParse(val) ?? 0;
                                notifier.updateSubject(
                                  idx,
                                  sub.copyWith(obtainedMarks: n),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              initialValue: sub.maxMarks.toString(),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Total Marks',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (val) {
                                final n = double.tryParse(val) ?? 100;
                                notifier.updateSubject(
                                  idx,
                                  sub.copyWith(maxMarks: n),
                                );
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
            const SizedBox(height: 8),

            // Add Subject Button
            AppButton(
              text: '+ Add Another Subject',
              variant: AppButtonVariant.outline,
              onPressed: () {
                notifier.addSubject(name: 'Subject ${subjects.length + 1}');
                setState(() => _result = null);
              },
            ),
            const SizedBox(height: 16),

            // Calculate Button
            AppButton(
              text: 'Calculate Overall Total & Percentage',
              variant: AppButtonVariant.primary,
              onPressed: _calculate,
            ),
            const SizedBox(height: 24),

            // Result Display Card
            if (_result != null) ...[
              AppCard(
                child: Column(
                  children: [
                    const Text(
                      'Cumulative Grade Result',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${_result!.overallPercentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Percentage',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 50,
                          width: 1,
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                        Column(
                          children: [
                            Text(
                              _result!.overallGrade,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Standard Grade',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Text(
                      'Total: ${_result!.totalObtained} / ${_result!.totalMax} marks across ${_result!.subjectCount} subjects',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy Results Summary'),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                'Overall Result: ${_result!.overallPercentage.toStringAsFixed(1)}% (Grade: ${_result!.overallGrade})\nTotal: ${_result!.totalObtained}/${_result!.totalMax}',
                          ),
                        );
                        AppDialogs.showSnackBar(
                          context,
                          message: 'Summary copied to clipboard!',
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
