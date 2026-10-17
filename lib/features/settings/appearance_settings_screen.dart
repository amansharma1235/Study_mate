import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/app_card.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTheme = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Appearance & Theme')),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Theme Mode',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              context,
              ref,
              title: 'Light Theme',
              subtitle: 'Clean, radiant design with indigo accents',
              icon: Icons.light_mode_rounded,
              mode: ThemeMode.light,
              current: currentTheme,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildThemeOption(
              context,
              ref,
              title: 'Dark Theme',
              subtitle: 'Midnight palette engineered for low eye strain',
              icon: Icons.dark_mode_rounded,
              mode: ThemeMode.dark,
              current: currentTheme,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildThemeOption(
              context,
              ref,
              title: 'System Default',
              subtitle: 'Follows your Android system display settings',
              icon: Icons.settings_brightness_rounded,
              mode: ThemeMode.system,
              current: currentTheme,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode current,
    required bool isDark,
  }) {
    final isSelected = mode == current;

    return AppCard(
      onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(mode),
      border: Border.all(
        color: isSelected
            ? AppColors.primary
            : (isDark ? AppColors.borderDark : AppColors.borderLight),
        width: isSelected ? 2 : 1,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : (isDark
                        ? AppColors.surfaceDark
                        : AppColors.backgroundLight),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondaryLight,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDimensions.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 22,
            ),
        ],
      ),
    );
  }
}
