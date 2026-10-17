import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../core/widgets/app_text_field.dart';
import 'calculator_controller.dart';

class PercentageCalculatorScreen extends ConsumerStatefulWidget {
  const PercentageCalculatorScreen({super.key});

  @override
  ConsumerState<PercentageCalculatorScreen> createState() =>
      _PercentageCalculatorScreenState();
}

class _PercentageCalculatorScreenState
    extends ConsumerState<PercentageCalculatorScreen> {
  final _obtainedController = TextEditingController();
  final _maxController = TextEditingController();

  @override
  void dispose() {
    _obtainedController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _calculate() {
    ref
        .read(percentageCalculatorProvider.notifier)
        .calculate(_obtainedController.text, _maxController.text);
  }

  void _reset() {
    _obtainedController.clear();
    _maxController.clear();
    ref.read(percentageCalculatorProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final calcState = ref.watch(percentageCalculatorProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Percentage Calculator'),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.multiSubjectCalculator),
            child: const Text(
              'Multi-Subject',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Calculate Single Exam Percentage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Formula: (Obtained Marks ÷ Total Marks) × 100',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppDimensions.space24),

            AppTextField(
              label: 'Marks Obtained',
              hint: 'e.g. 84.5',
              controller: _obtainedController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixIcon: Icons.score_outlined,
            ),
            const SizedBox(height: AppDimensions.space16),

            AppTextField(
              label: 'Maximum Possible Marks',
              hint: 'e.g. 100',
              controller: _maxController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixIcon: Icons.format_list_numbered_rounded,
            ),
            const SizedBox(height: AppDimensions.space20),

            if (calcState.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        calcState.error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space20),
            ],

            Row(
              children: [
                Expanded(
                  child: AppButton(text: 'Calculate', onPressed: _calculate),
                ),
                const SizedBox(width: 12),
                AppButton(
                  text: 'Clear',
                  variant: AppButtonVariant.outline,
                  onPressed: _reset,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space32),

            // Result Display Card
            if (calcState.percentage != null) ...[
              AppCard(
                child: Column(
                  children: [
                    const Text(
                      'Calculated Result',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${calcState.percentage!.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${calcState.obtainedMarks} out of ${calcState.maxMarks} marks',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copy Result'),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text:
                                    '${calcState.percentage!.toStringAsFixed(2)}%',
                              ),
                            );
                            AppDialogs.showSnackBar(
                              context,
                              message: 'Result copied to clipboard!',
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
