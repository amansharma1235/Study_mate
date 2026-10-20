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
    final currentAccent = ref.watch(accentThemeProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Appearance & Themes',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        children: [
          // Live Theme Preview Card
          _buildLivePreviewCard(context, isDark, currentAccent),
          const SizedBox(height: 24),

          // Theme Mode Section
          Text(
            'Display Mode',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
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
            subtitle: 'Clean, radiant porcelain slate for daytime studying',
            icon: Icons.light_mode_rounded,
            mode: ThemeMode.light,
            current: currentTheme,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildThemeOption(
            context,
            ref,
            title: 'Midnight Dark (AMOLED)',
            subtitle: 'Ultra-deep eye-saving black palette with frosted slate cards',
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
            subtitle: 'Syncs automatically with your Android system settings',
            icon: Icons.settings_brightness_rounded,
            mode: ThemeMode.system,
            current: currentTheme,
            isDark: isDark,
          ),

          const SizedBox(height: 28),

          // Accent Palettes Section
          Text(
            'Brand Accent Palette',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Personalize the signature highlights, buttons, and progress rings across the app.',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 14),

          ...AccentTheme.values.map(
            (accent) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildAccentTile(
                context,
                ref,
                accent: accent,
                isSelected: accent == currentAccent,
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard(
    BuildContext context,
    bool isDark,
    AccentTheme accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF161C2C), const Color(0xFF0F1422)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.primaryColor.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: accent.gradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.palette_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Live Palette Preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                accent.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accent.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Master Your Learning Journey',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Study sessions, AI tutor cards, and countdown rings reflect your custom colors.',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.primaryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accent.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 14, color: accent.secondaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '7 Day Streak',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.secondaryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accent.secondaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 13, color: accent.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'AI Tutor Ready',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
    final primary = Theme.of(context).primaryColor;

    return AppCard(
      onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(mode),
      border: Border.all(
        color: isSelected
            ? primary
            : (isDark ? AppColors.borderDark : AppColors.borderLight),
        width: isSelected ? 2 : 1,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? primary.withValues(alpha: 0.15)
                  : (isDark
                      ? const Color(0xFF1E2436)
                      : AppColors.backgroundLight),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Icon(
              icon,
              color: isSelected ? primary : AppColors.textSecondaryLight,
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
            Icon(
              Icons.check_circle_rounded,
              color: primary,
              size: 22,
            ),
        ],
      ),
    );
  }

  Widget _buildAccentTile(
    BuildContext context,
    WidgetRef ref, {
    required AccentTheme accent,
    required bool isSelected,
    required bool isDark,
  }) {
    return AppCard(
      onTap: () {
        ref.read(accentThemeProvider.notifier).setAccentTheme(accent);
      },
      border: Border.all(
        color: isSelected
            ? accent.primaryColor
            : (isDark ? AppColors.borderDark : AppColors.borderLight),
        width: isSelected ? 2 : 1,
      ),
      child: Row(
        children: [
          // Color Swatches Circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: accent.gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.primaryColor.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: isSelected
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 22,
                  )
                : null,
          ),
          const SizedBox(width: AppDimensions.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      accent.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    if (accent == AccentTheme.studyMate) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Official',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  accent.subtitle,
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
            Icon(
              Icons.radio_button_checked_rounded,
              color: accent.primaryColor,
              size: 22,
            )
          else
            Icon(
              Icons.radio_button_off_rounded,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              size: 22,
            ),
        ],
      ),
    );
  }
}
