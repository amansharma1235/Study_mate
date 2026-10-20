import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final double? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.space16),
    this.onTap,
    this.color,
    this.gradient,
    this.border,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? AppDimensions.radiusLarge;

    final cardColor =
        color ?? (isDark ? AppColors.cardDark : AppColors.cardLight);
    final cardBorder =
        border ??
        Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.1,
        );

    final shadows = isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ];

    final cardDecoration = BoxDecoration(
      color: gradient == null ? cardColor : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(r),
      border: cardBorder,
      boxShadow: shadows,
    );

    if (onTap != null) {
      return Container(
        decoration: cardDecoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(r),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(r),
            splashColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
            highlightColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
            onTap: onTap,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: cardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(r),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
